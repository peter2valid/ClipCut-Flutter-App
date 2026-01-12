import 'package:hive/hive.dart';

part 'export_settings.g.dart';

/// Resolution options for export
@HiveType(typeId: 5)
enum ExportResolution {
  @HiveField(0)
  hd720p, // 1280x720

  @HiveField(1)
  fullHd1080p, // 1920x1080
}

/// Settings for video export
@HiveType(typeId: 6)
class ExportSettings {
  @HiveField(0)
  final ExportResolution resolution;

  @HiveField(1)
  final int videoBitrate; // in kbps

  @HiveField(2)
  final int audioBitrate; // in kbps

  @HiveField(3)
  final int frameRate;

  @HiveField(4)
  final String outputFormat; // mp4, mov, etc.

  const ExportSettings({
    this.resolution = ExportResolution.fullHd1080p,
    this.videoBitrate = 8000,
    this.audioBitrate = 192,
    this.frameRate = 30,
    this.outputFormat = 'mp4',
  });

  /// Get width based on resolution
  int get width {
    switch (resolution) {
      case ExportResolution.hd720p:
        return 1280;
      case ExportResolution.fullHd1080p:
        return 1920;
    }
  }

  /// Get height based on resolution
  int get height {
    switch (resolution) {
      case ExportResolution.hd720p:
        return 720;
      case ExportResolution.fullHd1080p:
        return 1080;
    }
  }

  /// Get resolution display name
  String get resolutionName {
    switch (resolution) {
      case ExportResolution.hd720p:
        return '720p HD';
      case ExportResolution.fullHd1080p:
        return '1080p Full HD';
    }
  }

  /// Default settings for high quality export
  factory ExportSettings.highQuality() {
    return const ExportSettings(
      resolution: ExportResolution.fullHd1080p,
      videoBitrate: 12000,
      audioBitrate: 256,
      frameRate: 30,
    );
  }

  /// Default settings for balanced quality/size
  factory ExportSettings.balanced() {
    return const ExportSettings(
      resolution: ExportResolution.fullHd1080p,
      videoBitrate: 8000,
      audioBitrate: 192,
      frameRate: 30,
    );
  }

  /// Default settings for smaller file size
  factory ExportSettings.compact() {
    return const ExportSettings(
      resolution: ExportResolution.hd720p,
      videoBitrate: 4000,
      audioBitrate: 128,
      frameRate: 30,
    );
  }

  /// Create a copy with updated values
  ExportSettings copyWith({
    ExportResolution? resolution,
    int? videoBitrate,
    int? audioBitrate,
    int? frameRate,
    String? outputFormat,
  }) {
    return ExportSettings(
      resolution: resolution ?? this.resolution,
      videoBitrate: videoBitrate ?? this.videoBitrate,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      frameRate: frameRate ?? this.frameRate,
      outputFormat: outputFormat ?? this.outputFormat,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExportSettings &&
        other.resolution == resolution &&
        other.videoBitrate == videoBitrate &&
        other.audioBitrate == audioBitrate &&
        other.frameRate == frameRate &&
        other.outputFormat == outputFormat;
  }

  @override
  int get hashCode {
    return Object.hash(
      resolution,
      videoBitrate,
      audioBitrate,
      frameRate,
      outputFormat,
    );
  }
}
