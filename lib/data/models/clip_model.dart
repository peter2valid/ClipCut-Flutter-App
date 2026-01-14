import 'package:uuid/uuid.dart';

/// Represents a video clip with start/end times and selection state
class ClipModel {
  final String id;
  final String path;
  final Duration start;
  final Duration end;
  final String? thumbnailPath;
  bool selected;

  ClipModel({
    String? id,
    required this.path,
    required this.start,
    required this.end,
    this.thumbnailPath,
    this.selected = true,
  }) : id = id ?? const Uuid().v4();

  /// Get the duration of this clip
  Duration get duration => end - start;

  /// Get the expected exported filename for a clip at given index
  /// Format: clip_000.mp4, clip_001.mp4, clip_002.mp4, etc.
  static String getExportedFileName(int index) {
    return 'clip_${index.toString().padLeft(3, '0')}.mp4';
  }

  /// Create from JSON (for Hive storage)
  factory ClipModel.fromJson(Map<String, dynamic> json) {
    return ClipModel(
      id: json['id'] as String,
      path: json['path'] as String,
      start: Duration(milliseconds: json['startMs'] as int),
      end: Duration(milliseconds: json['endMs'] as int),
      thumbnailPath: json['thumbnailPath'] as String?,
      selected: json['selected'] as bool? ?? true,
    );
  }

  /// Convert to JSON (for Hive storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'startMs': start.inMilliseconds,
      'endMs': end.inMilliseconds,
      'thumbnailPath': thumbnailPath,
      'selected': selected,
    };
  }

  /// Create a copy with modified fields
  ClipModel copyWith({
    String? id,
    String? path,
    Duration? start,
    Duration? end,
    String? thumbnailPath,
    bool? selected,
  }) {
    return ClipModel(
      id: id ?? this.id,
      path: path ?? this.path,
      start: start ?? this.start,
      end: end ?? this.end,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      selected: selected ?? this.selected,
    );
  }

  @override
  String toString() {
    return 'ClipModel(id: $id, path: $path, start: $start, end: $end, selected: $selected)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClipModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
