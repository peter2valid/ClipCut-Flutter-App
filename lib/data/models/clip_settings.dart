import 'package:hive/hive.dart';

part 'clip_settings.g.dart';

/// Aspect ratio options for clips
@HiveType(typeId: 3)
enum AspectRatioType {
  @HiveField(0)
  portrait9x16, // 9:16 - TikTok, Reels, Shorts

  @HiveField(1)
  square1x1, // 1:1 - Instagram square

  @HiveField(2)
  landscape16x9, // 16:9 - YouTube, standard widescreen
}

/// Background type options for non-native aspect ratios
@HiveType(typeId: 4)
enum BackgroundType {
  @HiveField(0)
  blur, // Blurred version of video

  @HiveField(1)
  blackBars, // Black letterbox/pillarbox

  @HiveField(2)
  solidColor, // Custom solid color
}

/// Settings for individual clip editing
@HiveType(typeId: 2)
class ClipSettings {
  @HiveField(0)
  final int trimStartMs; // Milliseconds offset from clip start

  @HiveField(1)
  final int trimEndMs; // Milliseconds offset from clip end (negative = trim)

  @HiveField(2)
  final AspectRatioType aspectRatio;

  @HiveField(3)
  final BackgroundType backgroundType;

  @HiveField(4)
  final int? backgroundColor; // ARGB int for solid color

  @HiveField(5)
  final String? audioPath; // Path to overlay audio file

  @HiveField(6)
  final double audioVolume; // Audio volume 0.0 - 1.0

  @HiveField(7)
  final bool muteOriginalAudio; // Whether to mute the original video audio

  const ClipSettings({
    this.trimStartMs = 0,
    this.trimEndMs = 0,
    this.aspectRatio = AspectRatioType.portrait9x16,
    this.backgroundType = BackgroundType.blur,
    this.backgroundColor,
    this.audioPath,
    this.audioVolume = 1.0,
    this.muteOriginalAudio = false,
  });

  /// Default settings factory
  factory ClipSettings.defaultSettings() {
    return const ClipSettings();
  }

  /// Get trim start as Duration
  Duration get trimStart => Duration(milliseconds: trimStartMs);

  /// Get trim end as Duration
  Duration get trimEnd => Duration(milliseconds: trimEndMs);

  /// Get aspect ratio as double value
  double get aspectRatioValue {
    switch (aspectRatio) {
      case AspectRatioType.portrait9x16:
        return 9 / 16;
      case AspectRatioType.square1x1:
        return 1.0;
      case AspectRatioType.landscape16x9:
        return 16 / 9;
    }
  }

  /// Get aspect ratio display name
  String get aspectRatioName {
    switch (aspectRatio) {
      case AspectRatioType.portrait9x16:
        return '9:16';
      case AspectRatioType.square1x1:
        return '1:1';
      case AspectRatioType.landscape16x9:
        return '16:9';
    }
  }

  /// Get background type display name
  String get backgroundTypeName {
    switch (backgroundType) {
      case BackgroundType.blur:
        return 'Blur';
      case BackgroundType.blackBars:
        return 'Black';
      case BackgroundType.solidColor:
        return 'Color';
    }
  }

  /// Create a copy with updated values
  ClipSettings copyWith({
    int? trimStartMs,
    int? trimEndMs,
    AspectRatioType? aspectRatio,
    BackgroundType? backgroundType,
    int? backgroundColor,
    String? audioPath,
    double? audioVolume,
    bool? muteOriginalAudio,
  }) {
    return ClipSettings(
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      backgroundType: backgroundType ?? this.backgroundType,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      audioPath: audioPath ?? this.audioPath,
      audioVolume: audioVolume ?? this.audioVolume,
      muteOriginalAudio: muteOriginalAudio ?? this.muteOriginalAudio,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClipSettings &&
        other.trimStartMs == trimStartMs &&
        other.trimEndMs == trimEndMs &&
        other.aspectRatio == aspectRatio &&
        other.backgroundType == backgroundType &&
        other.backgroundColor == backgroundColor &&
        other.audioPath == audioPath &&
        other.audioVolume == audioVolume &&
        other.muteOriginalAudio == muteOriginalAudio;
  }

  @override
  int get hashCode {
    return Object.hash(
      trimStartMs,
      trimEndMs,
      aspectRatio,
      backgroundType,
      backgroundColor,
      audioPath,
      audioVolume,
      muteOriginalAudio,
    );
  }
}
