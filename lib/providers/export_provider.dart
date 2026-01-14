import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';
import '../services/services.dart';
import '../core/utils/file_utils.dart';
import 'project_provider.dart';

/// State for export operations
/// Updated for segment-based export (single FFmpeg call for all clips)
class ExportState {
  final bool isExporting;
  final int totalClips;
  final double overallProgress; // 0.0 to 1.0 for entire export
  final List<String> exportedPaths;
  final String? error;
  final DateTime? startTime; // When export started

  const ExportState({
    this.isExporting = false,
    this.totalClips = 0,
    this.overallProgress = 0.0,
    this.exportedPaths = const [],
    this.error,
    this.startTime,
  });

  /// Elapsed time since export started
  Duration get elapsedTime {
    if (startTime == null) return Duration.zero;
    return DateTime.now().difference(startTime!);
  }

  /// Formatted elapsed time (MM:SS)
  String get formattedTime {
    final duration = elapsedTime;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Progress text for UI display with elapsed time
  String get progressText {
    if (!isExporting) return '';
    return 'Exporting $totalClips clips ($formattedTime)';
  }

  /// Progress percentage (0-100)
  int get progressPercent => (overallProgress * 100).round();

  ExportState copyWith({
    bool? isExporting,
    int? totalClips,
    double? overallProgress,
    List<String>? exportedPaths,
    String? error,
    DateTime? startTime,
    bool clearStartTime = false,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      totalClips: totalClips ?? this.totalClips,
      overallProgress: overallProgress ?? this.overallProgress,
      exportedPaths: exportedPaths ?? this.exportedPaths,
      error: error,
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
    );
  }
}

/// Notifier for managing export operations
class ExportNotifier extends StateNotifier<ExportState> {
  final Ref _ref;

  ExportNotifier(this._ref) : super(const ExportState());

  /// Export a single clip
  Future<String?> exportSingleClip({
    required VideoClip clip,
    required ExportSettings settings,
  }) async {
    final project = _ref.read(projectProvider).project;
    if (project == null) return null;

    state = state.copyWith(
      isExporting: true,
      totalClips: 1,
      overallProgress: 0.0,
      exportedPaths: [],
      error: null,
    );

    try {
      final outputDir = await FFmpegService.getExportDirectory();

      final path = await FFmpegService.exportClip(
        inputPath: project.sourceVideoPath,
        clip: clip,
        settings: settings,
        outputDir: outputDir,
        onProgress: (progress) {
          state = state.copyWith(overallProgress: progress);
        },
      );

      if (path != null) {
        // Trigger media scanner so file appears in Gallery immediately
        await MediaScannerService.scanFile(path);

        // Update clip with exported path
        final updatedClip = clip.markExported(path);
        _ref.read(projectProvider.notifier).updateClip(updatedClip);

        state = state.copyWith(
          isExporting: false,
          exportedPaths: [path],
        );

        return path;
      } else {
        state = state.copyWith(
          isExporting: false,
          error: 'Export failed',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// ⚡ EXPORT via -c copy using snapped timestamps
  Future<List<String>> exportAllClips({
    required ExportSettings settings,
    List<VideoClip>? clipsToExport,
  }) async {
    final project = _ref.read(projectProvider).project;
    if (project == null) return [];
    final clips = clipsToExport ?? project.clips;
    if (clips.isEmpty) return [];

    state = state.copyWith(
      isExporting: true,
      totalClips: clips.length,
      overallProgress: 0.0,
      exportedPaths: [],
      error: null,
      startTime: DateTime.now(),
    );

    try {
      final dir = await FFmpegService.getExportDirectory();
      await Directory(dir).create(recursive: true);

      final out = <String>[];

      for (int i = 0; i < clips.length; i++) {
        final c = clips[i];
        final snapStart = await FFmpegService.snapToKeyframe(
            project.sourceVideoPath, Duration(milliseconds: c.startTimeMs));
        final snapEnd = await FFmpegService.snapToKeyframe(
            project.sourceVideoPath, Duration(milliseconds: c.endTimeMs));
        final path = '$dir/clip_${i.toString().padLeft(3, '0')}.mp4';

        final ok = await FFmpegService.exportFastClip(
          inputPath: project.sourceVideoPath,
          startTime: snapStart,
          endTime: snapEnd,
          outputPath: path,
        );

        if (ok) {
          out.add(path);
          await MediaScannerService.scanFile(path);
        }

        state = state.copyWith(overallProgress: (i + 1) / clips.length);
      }

      await Future.delayed(const Duration(milliseconds: 500));
      await MediaScannerService.scanFiles(out);

      state = state.copyWith(
        isExporting: false,
        exportedPaths: out,
        overallProgress: 1.0,
        clearStartTime: true,
      );
      return out;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
        clearStartTime: true,
      );
      return [];
    }
  }

  /// Cancel export
  Future<void> cancelExport() async {
    await FFmpegService.cancelAll();
    state = state.copyWith(isExporting: false);
  }

  /// Reset export state
  void reset() {
    state = const ExportState();
  }
}

/// Provider for export operations
final exportProvider =
    StateNotifierProvider<ExportNotifier, ExportState>((ref) {
  return ExportNotifier(ref);
});

/// Provider for export settings
final exportSettingsProvider = StateProvider<ExportSettings>((ref) {
  return ExportSettings.balanced();
});
