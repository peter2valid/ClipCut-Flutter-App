import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';
import '../services/services.dart';
import 'project_provider.dart';

/// State for export operations
class ExportState {
  final bool isExporting;
  final int currentClipIndex;
  final int totalClips;
  final double currentClipProgress;
  final List<String> exportedPaths;
  final String? error;

  const ExportState({
    this.isExporting = false,
    this.currentClipIndex = 0,
    this.totalClips = 0,
    this.currentClipProgress = 0.0,
    this.exportedPaths = const [],
    this.error,
  });

  /// Overall progress (0.0 to 1.0)
  double get overallProgress {
    if (totalClips == 0) return 0.0;
    final completed = (currentClipIndex - 1).clamp(0, totalClips);
    final current = currentClipProgress / totalClips;
    return (completed / totalClips) + current;
  }

  /// Progress text
  String get progressText {
    if (!isExporting) return '';
    return 'Exporting clip $currentClipIndex of $totalClips';
  }

  ExportState copyWith({
    bool? isExporting,
    int? currentClipIndex,
    int? totalClips,
    double? currentClipProgress,
    List<String>? exportedPaths,
    String? error,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      currentClipIndex: currentClipIndex ?? this.currentClipIndex,
      totalClips: totalClips ?? this.totalClips,
      currentClipProgress: currentClipProgress ?? this.currentClipProgress,
      exportedPaths: exportedPaths ?? this.exportedPaths,
      error: error,
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
      currentClipIndex: 1,
      totalClips: 1,
      currentClipProgress: 0.0,
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
          state = state.copyWith(currentClipProgress: progress);
        },
      );

      if (path != null) {
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

  /// Export all clips (or selected clips)
  Future<List<String>> exportAllClips({
    required ExportSettings settings,
    List<VideoClip>? clipsToExport,
  }) async {
    final project = _ref.read(projectProvider).project;
    if (project == null) return [];

    final clips = clipsToExport ?? project.clips;

    state = state.copyWith(
      isExporting: true,
      currentClipIndex: 0,
      totalClips: clips.length,
      currentClipProgress: 0.0,
      exportedPaths: [],
      error: null,
    );

    try {
      final outputDir = await FFmpegService.getExportDirectory();
      final exportedPaths = <String>[];

      for (int i = 0; i < clips.length; i++) {
        state = state.copyWith(
          currentClipIndex: i + 1,
          currentClipProgress: 0.0,
        );

        final path = await FFmpegService.exportClip(
          inputPath: project.sourceVideoPath,
          clip: clips[i],
          settings: settings,
          outputDir: outputDir,
          onProgress: (progress) {
            state = state.copyWith(currentClipProgress: progress);
          },
        );

        if (path != null) {
          exportedPaths.add(path);

          // Update clip with exported path
          final updatedClip = clips[i].markExported(path);
          _ref.read(projectProvider.notifier).updateClip(updatedClip);
        }
      }

      state = state.copyWith(
        isExporting: false,
        exportedPaths: exportedPaths,
      );

      return exportedPaths;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
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
