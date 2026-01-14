/// Progress tracking for batch export operations
class ExportProgress {
  final int totalClips;
  final int currentClipIndex;
  final double currentClipProgress;
  final String? currentClipPath;
  final List<String> completedPaths;
  final List<String> failedClips;
  final bool isCancelled;
  final String? error;

  ExportProgress({
    required this.totalClips,
    this.currentClipIndex = 0,
    this.currentClipProgress = 0.0,
    this.currentClipPath,
    this.completedPaths = const [],
    this.failedClips = const [],
    this.isCancelled = false,
    this.error,
  });

  /// Get overall batch progress (0.0 to 1.0)
  double get batchProgress {
    if (totalClips == 0) return 0.0;

    final completedFraction = currentClipIndex / totalClips;
    final currentFraction = currentClipProgress / totalClips;

    return (completedFraction + currentFraction).clamp(0.0, 1.0);
  }

  /// Get percentage string for display
  String get percentageString {
    return '${(batchProgress * 100).toStringAsFixed(0)}%';
  }

  /// Check if export is complete
  bool get isComplete {
    return currentClipIndex >= totalClips && !isCancelled;
  }

  /// Check if there were any failures
  bool get hasFailures => failedClips.isNotEmpty;

  /// Get success rate
  double get successRate {
    if (totalClips == 0) return 0.0;
    return completedPaths.length / totalClips;
  }

  ExportProgress copyWith({
    int? totalClips,
    int? currentClipIndex,
    double? currentClipProgress,
    String? currentClipPath,
    List<String>? completedPaths,
    List<String>? failedClips,
    bool? isCancelled,
    String? error,
  }) {
    return ExportProgress(
      totalClips: totalClips ?? this.totalClips,
      currentClipIndex: currentClipIndex ?? this.currentClipIndex,
      currentClipProgress: currentClipProgress ?? this.currentClipProgress,
      currentClipPath: currentClipPath ?? this.currentClipPath,
      completedPaths: completedPaths ?? this.completedPaths,
      failedClips: failedClips ?? this.failedClips,
      isCancelled: isCancelled ?? this.isCancelled,
      error: error,
    );
  }

  @override
  String toString() {
    return 'ExportProgress(${currentClipIndex}/${totalClips}, '
        '${percentageString}, completed: ${completedPaths.length}, '
        'failed: ${failedClips.length})';
  }
}
