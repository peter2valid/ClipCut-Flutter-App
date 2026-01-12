import 'package:hive/hive.dart';
import 'clip_settings.dart';

part 'video_clip.g.dart';

/// Represents a single clip segment from the source video
@HiveType(typeId: 1)
class VideoClip {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int index; // Order in the clip list

  @HiveField(2)
  final int startTimeMs; // Start time in source video (milliseconds)

  @HiveField(3)
  final int endTimeMs; // End time in source video (milliseconds)

  @HiveField(4)
  final String? thumbnailPath; // Path to generated thumbnail

  @HiveField(5)
  final ClipSettings settings; // Editing settings

  @HiveField(6)
  final String? exportedPath; // Path to exported file (if exported)

  @HiveField(7)
  final bool isSelected; // For batch selection UI

  const VideoClip({
    required this.id,
    required this.index,
    required this.startTimeMs,
    required this.endTimeMs,
    this.thumbnailPath,
    required this.settings,
    this.exportedPath,
    this.isSelected = false,
  });

  /// Get start time as Duration
  Duration get startTime => Duration(milliseconds: startTimeMs);

  /// Get end time as Duration
  Duration get endTime => Duration(milliseconds: endTimeMs);

  /// Get original clip duration (before any trimming)
  Duration get originalDuration =>
      Duration(milliseconds: endTimeMs - startTimeMs);

  /// Get effective duration after trimming applied
  Duration get effectiveDuration {
    final start = startTimeMs + settings.trimStartMs;
    final end =
        endTimeMs + settings.trimEndMs; // trimEndMs is negative for trimming
    return Duration(milliseconds: end - start);
  }

  /// Get effective start time in source video (after trim)
  Duration get effectiveStartTime =>
      Duration(milliseconds: startTimeMs + settings.trimStartMs);

  /// Get effective end time in source video (after trim)
  Duration get effectiveEndTime =>
      Duration(milliseconds: endTimeMs + settings.trimEndMs);

  /// Check if clip has been exported
  bool get isExported => exportedPath != null && exportedPath!.isNotEmpty;

  /// Check if clip has any custom edits applied
  bool get hasEdits {
    final defaultSettings = ClipSettings.defaultSettings();
    return settings != defaultSettings;
  }

  /// Create a copy with updated values
  VideoClip copyWith({
    String? id,
    int? index,
    int? startTimeMs,
    int? endTimeMs,
    String? thumbnailPath,
    ClipSettings? settings,
    String? exportedPath,
    bool? isSelected,
  }) {
    return VideoClip(
      id: id ?? this.id,
      index: index ?? this.index,
      startTimeMs: startTimeMs ?? this.startTimeMs,
      endTimeMs: endTimeMs ?? this.endTimeMs,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      settings: settings ?? this.settings,
      exportedPath: exportedPath ?? this.exportedPath,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  /// Clear the thumbnail path
  VideoClip clearThumbnail() {
    return copyWith(thumbnailPath: null);
  }

  /// Mark as exported with path
  VideoClip markExported(String path) {
    return copyWith(exportedPath: path);
  }

  /// Toggle selection state
  VideoClip toggleSelection() {
    return copyWith(isSelected: !isSelected);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoClip &&
        other.id == id &&
        other.index == index &&
        other.startTimeMs == startTimeMs &&
        other.endTimeMs == endTimeMs &&
        other.thumbnailPath == thumbnailPath &&
        other.settings == settings &&
        other.exportedPath == exportedPath &&
        other.isSelected == isSelected;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      index,
      startTimeMs,
      endTimeMs,
      thumbnailPath,
      settings,
      exportedPath,
      isSelected,
    );
  }

  @override
  String toString() {
    return 'VideoClip(id: $id, index: $index, start: $startTimeMs, end: $endTimeMs)';
  }
}
