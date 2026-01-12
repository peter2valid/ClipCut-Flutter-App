import 'package:hive/hive.dart';
import 'video_clip.dart';

part 'video_project.g.dart';

/// Represents a complete video editing project
@HiveType(typeId: 0)
class VideoProject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String sourceVideoPath;

  @HiveField(3)
  final int sourceDurationMs; // Total source video duration in milliseconds

  @HiveField(4)
  final int sourceWidth;

  @HiveField(5)
  final int sourceHeight;

  @HiveField(6)
  final int clipDurationMs; // Selected clip duration in milliseconds

  @HiveField(7)
  final List<VideoClip> clips;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  @HiveField(10)
  final String? sourceThumbnailPath; // Thumbnail of source video

  const VideoProject({
    required this.id,
    required this.name,
    required this.sourceVideoPath,
    required this.sourceDurationMs,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.clipDurationMs,
    required this.clips,
    required this.createdAt,
    required this.updatedAt,
    this.sourceThumbnailPath,
  });

  /// Get source duration as Duration
  Duration get sourceDuration => Duration(milliseconds: sourceDurationMs);

  /// Get clip duration as Duration
  Duration get clipDuration => Duration(milliseconds: clipDurationMs);

  /// Get source aspect ratio
  double get sourceAspectRatio {
    if (sourceHeight == 0) return 16 / 9;
    return sourceWidth / sourceHeight;
  }

  /// Get total number of clips
  int get clipCount => clips.length;

  /// Get number of exported clips
  int get exportedClipCount => clips.where((c) => c.isExported).length;

  /// Get number of selected clips
  int get selectedClipCount => clips.where((c) => c.isSelected).length;

  /// Check if all clips are exported
  bool get allClipsExported => clips.every((c) => c.isExported);

  /// Check if any clip has edits
  bool get hasAnyEdits => clips.any((c) => c.hasEdits);

  /// Get clip by ID
  VideoClip? getClipById(String clipId) {
    try {
      return clips.firstWhere((c) => c.id == clipId);
    } catch (_) {
      return null;
    }
  }

  /// Get clip by index
  VideoClip? getClipByIndex(int index) {
    if (index < 0 || index >= clips.length) return null;
    return clips[index];
  }

  /// Create a copy with updated values
  VideoProject copyWith({
    String? id,
    String? name,
    String? sourceVideoPath,
    int? sourceDurationMs,
    int? sourceWidth,
    int? sourceHeight,
    int? clipDurationMs,
    List<VideoClip>? clips,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sourceThumbnailPath,
  }) {
    return VideoProject(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceVideoPath: sourceVideoPath ?? this.sourceVideoPath,
      sourceDurationMs: sourceDurationMs ?? this.sourceDurationMs,
      sourceWidth: sourceWidth ?? this.sourceWidth,
      sourceHeight: sourceHeight ?? this.sourceHeight,
      clipDurationMs: clipDurationMs ?? this.clipDurationMs,
      clips: clips ?? this.clips,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceThumbnailPath: sourceThumbnailPath ?? this.sourceThumbnailPath,
    );
  }

  /// Update a specific clip in the project
  VideoProject updateClip(VideoClip updatedClip) {
    final newClips = clips.map((c) {
      return c.id == updatedClip.id ? updatedClip : c;
    }).toList();
    return copyWith(
      clips: newClips,
      updatedAt: DateTime.now(),
    );
  }

  /// Update the timestamp
  VideoProject touch() {
    return copyWith(updatedAt: DateTime.now());
  }

  /// Select all clips
  VideoProject selectAllClips() {
    return copyWith(
      clips: clips.map((c) => c.copyWith(isSelected: true)).toList(),
    );
  }

  /// Deselect all clips
  VideoProject deselectAllClips() {
    return copyWith(
      clips: clips.map((c) => c.copyWith(isSelected: false)).toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoProject && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'VideoProject(id: $id, name: $name, clips: ${clips.length})';
  }
}
