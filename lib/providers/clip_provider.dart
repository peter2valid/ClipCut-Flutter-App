import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/clip_model.dart';
import '../data/models/export_progress.dart';
import '../services/ffmpeg_service.dart';
import '../core/utils/file_utils.dart';

/// State class for clips
class ClipsState {
  final List<ClipModel> clips;
  final String? sourceVideoPath;
  final bool isLoading;
  final bool isProcessing; // ← P0 FIX: Guards against parallel operations
  final ExportProgress? exportProgress;
  final String? error;

  // ⚡ PERFORMANCE: Multi-stage progress tracking
  final double importProgress; // 0.0 - 1.0
  final double splitProgress; // 0.0 - 1.0
  final double thumbnailProgress; // 0.0 - 1.0

  ClipsState({
    this.clips = const [],
    this.sourceVideoPath,
    this.isLoading = false,
    this.isProcessing = false,
    this.exportProgress,
    this.error,
    this.importProgress = 0.0,
    this.splitProgress = 0.0,
    this.thumbnailProgress = 0.0,
  });

  ClipsState copyWith({
    List<ClipModel>? clips,
    String? sourceVideoPath,
    bool? isLoading,
    bool? isProcessing,
    ExportProgress? exportProgress,
    String? error,
    bool clearExportProgress = false,
    double? importProgress,
    double? splitProgress,
    double? thumbnailProgress,
  }) {
    return ClipsState(
      clips: clips ?? this.clips,
      sourceVideoPath: sourceVideoPath ?? this.sourceVideoPath,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      exportProgress:
          clearExportProgress ? null : (exportProgress ?? this.exportProgress),
      error: error,
      importProgress: importProgress ?? this.importProgress,
      splitProgress: splitProgress ?? this.splitProgress,
      thumbnailProgress: thumbnailProgress ?? this.thumbnailProgress,
    );
  }

  /// ⚡ PERFORMANCE: Calculate overall progress across all stages
  double get totalProgress =>
      (importProgress + splitProgress + thumbnailProgress) / 3;

  /// Get only selected clips
  List<ClipModel> get selectedClips => clips.where((c) => c.selected).toList();

  /// Check if any clips are selected
  bool get hasSelectedClips => clips.any((c) => c.selected);

  /// Get count of selected clips
  int get selectedCount => clips.where((c) => c.selected).length;
}

/// Notifier for managing clips
class ClipsNotifier extends StateNotifier<ClipsState> {
  ClipsNotifier() : super(ClipsState());

  /// ⚡⚡⚡ ZERO-COPY SPLIT: Instant (no temp files)
  Future<void> splitVideo({
    required String videoPath,
    required int durationSeconds,
    Function(int current, int total)? onProgress,
  }) async {
    if (state.isProcessing || state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      isProcessing: true,
      error: null,
      importProgress: 0.0,
      splitProgress: 0.0,
      thumbnailProgress: 0.0,
    );

    try {
      state = state.copyWith(importProgress: 0.2);
      final totalDuration = await FFmpegService.getDurationSeconds(videoPath);
      state = state.copyWith(importProgress: 1.0);

      final clips = <ClipModel>[];
      int totalDurationMs = (totalDuration * 1000).toInt();
      final clipDuration = Duration(seconds: durationSeconds);
      int currentStartMs = 0;
      int index = 0;
      final totalClips = (totalDuration / durationSeconds).ceil();

      while (currentStartMs < totalDurationMs) {
        int endMs = currentStartMs + clipDuration.inMilliseconds;
        if (endMs > totalDurationMs) endMs = totalDurationMs;
        if (endMs - currentStartMs >= 1000) {
          final startDuration = Duration(milliseconds: currentStartMs);
          final endDuration = Duration(milliseconds: endMs);

          final snappedStart =
              await FFmpegService.snapToKeyframe(videoPath, startDuration);
          final snappedEnd =
              await FFmpegService.snapToKeyframe(videoPath, endDuration);

          clips.add(ClipModel(
            path: videoPath,
            start: snappedStart,
            end: snappedEnd,
            thumbnailPath: null,
            selected: true,
          ));
          index++;
          state = state.copyWith(splitProgress: index / totalClips);
          onProgress?.call(index, totalClips);
        }
        currentStartMs = endMs;
      }

      state = state.copyWith(thumbnailProgress: 0.0);

      for (int i = 0; i < clips.length; i++) {
        final clip = clips[i];
        final mid = clip.start +
            Duration(milliseconds: (clip.end - clip.start).inMilliseconds ~/ 2);

        final thumbPath = await FFmpegService.generateThumbnail(
          videoPath: videoPath,
          timestamp: mid,
          outputDir: FileUtils.thumbDir,
        );
        clips[i] = clip.copyWith(thumbnailPath: thumbPath);
        state = state.copyWith(thumbnailProgress: (i + 1) / clips.length);
      }

      state = state.copyWith(
        clips: clips,
        sourceVideoPath: videoPath,
        isLoading: false,
        isProcessing: false,
        importProgress: 1.0,
        splitProgress: 1.0,
        thumbnailProgress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, isProcessing: false, error: e.toString());
    }
  }

  /// Export selected clips with progress tracking and cancellation
  /// Returns list of successfully exported paths
  Future<List<String>> exportSelectedClips({
    required String outputDir,
    Function(ExportProgress progress)? onProgress,
  }) async {
    // P0 FIX: Guard against parallel operations
    if (state.isProcessing) {
      throw Exception('Another operation is in progress');
    }

    final selectedClips = state.selectedClips;
    if (selectedClips.isEmpty) {
      throw Exception('No clips selected for export');
    }

    state = state.copyWith(
      isProcessing: true,
      exportProgress: ExportProgress(totalClips: selectedClips.length),
      error: null,
    );

    final exportedPaths = <String>[];
    final failedClips = <String>[];
    bool isCancelled = false;

    try {
      for (int i = 0; i < selectedClips.length; i++) {
        // Check cancellation
        if (state.exportProgress?.isCancelled ?? false) {
          isCancelled = true;
          break;
        }

        final clip = selectedClips[i];
        final clipName =
            'clip_${i + 1}_${DateTime.now().millisecondsSinceEpoch}';

        // Update progress: starting new clip
        final progress = ExportProgress(
          totalClips: selectedClips.length,
          currentClipIndex: i,
          currentClipProgress: 0.0,
          currentClipPath: clipName,
          completedPaths: List.from(exportedPaths),
          failedClips: List.from(failedClips),
        );

        state = state.copyWith(exportProgress: progress);
        onProgress?.call(progress);

        try {
          // Export single clip with inline progress updates
          final outputPath = await _exportSingleClip(
            clip: clip,
            outputDir: outputDir,
            clipName: clipName,
            onClipProgress: (clipProgress) {
              final updatedProgress = progress.copyWith(
                currentClipProgress: clipProgress,
              );
              state = state.copyWith(exportProgress: updatedProgress);
              onProgress?.call(updatedProgress);
            },
          );

          if (outputPath != null) {
            exportedPaths.add(outputPath);
          } else {
            failedClips.add(clip.id);
          }
        } catch (e) {
          print('[ClipProvider] Export failed for clip ${i + 1}: $e');
          failedClips.add(clip.id);
        }
      }

      // Final progress update
      final finalProgress = ExportProgress(
        totalClips: selectedClips.length,
        currentClipIndex: selectedClips.length,
        currentClipProgress: 1.0,
        completedPaths: List.from(exportedPaths),
        failedClips: List.from(failedClips),
        isCancelled: isCancelled,
      );

      state = state.copyWith(
        isProcessing: false,
        exportProgress: finalProgress,
      );
      onProgress?.call(finalProgress);

      return exportedPaths;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Export failed: $e',
      );
      rethrow;
    }
  }

  /// Export a single clip (helper method)
  /// Uses fast codec copy for maximum speed (instant completion, no progress tracking)
  Future<String?> _exportSingleClip({
    required ClipModel clip,
    required String outputDir,
    required String clipName,
    Function(double progress)? onClipProgress,
  }) async {
    try {
      final outputPath = '$outputDir/$clipName.mp4';

      // Use fast codec copy export (10x faster, instant completion)
      final result = await FFmpegService.exportFastClip(
        inputPath: clip.path,
        startTime: clip.start,
        endTime: clip.end,
        outputPath: outputPath,
      );

      // Immediately report completion since codec copy is near-instant
      onClipProgress?.call(1.0);

      return result ? outputPath : null;
    } catch (e) {
      print('[ClipProvider] Single clip export error: $e');
      return null;
    }
  }

  /// Cancel ongoing export
  void cancelExport() {
    if (state.exportProgress != null && !state.exportProgress!.isCancelled) {
      final cancelledProgress = state.exportProgress!.copyWith(
        isCancelled: true,
      );
      state = state.copyWith(exportProgress: cancelledProgress);

      // Cancel FFmpeg operations
      FFmpegService.cancelAll();
    }
  }

  /// Toggle clip selection
  void toggleClip(String clipId) {
    final updatedClips = state.clips.map((clip) {
      if (clip.id == clipId) {
        return clip.copyWith(selected: !clip.selected);
      }
      return clip;
    }).toList();

    state = state.copyWith(clips: updatedClips);
  }

  /// Select all clips
  void selectAll() {
    final updatedClips =
        state.clips.map((clip) => clip.copyWith(selected: true)).toList();

    state = state.copyWith(clips: updatedClips);
  }

  /// Deselect all clips
  void deselectAll() {
    final updatedClips =
        state.clips.map((clip) => clip.copyWith(selected: false)).toList();

    state = state.copyWith(clips: updatedClips);
  }

  /// Clear all clips (after export)
  Future<void> clearClips() async {
    // P0 FIX: Only cleanup if not processing
    if (state.isProcessing) {
      print('[ClipProvider] Cannot clear while processing');
      return;
    }

    // Clean up temp files
    await FFmpegService.cleanupTempClips();

    state = ClipsState();
  }

  /// Remove a specific clip
  void removeClip(String clipId) {
    final updatedClips =
        state.clips.where((clip) => clip.id != clipId).toList();
    state = state.copyWith(clips: updatedClips);
  }

  /// Update clip (for future editing features)
  void updateClip(ClipModel updatedClip) {
    final updatedClips = state.clips.map((clip) {
      if (clip.id == updatedClip.id) {
        return updatedClip;
      }
      return clip;
    }).toList();

    state = state.copyWith(clips: updatedClips);
  }
}

/// Provider for clips state
final clipsProvider = StateNotifierProvider<ClipsNotifier, ClipsState>((ref) {
  return ClipsNotifier();
});
