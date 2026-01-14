/// App-wide constants and configuration values
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'CLIPCUT';
  static const String appTagline = 'AUTO-CUT YOUR VIDEOS';
  static const String appVersion = '1.0.0';

  // Clip duration presets (in seconds)
  static const List<int> clipDurationPresets = [15, 30, 60, 90];
  static const int defaultClipDuration = 30;
  static const int minCustomDuration = 5;
  static const int maxCustomDuration = 300; // 5 minutes

  // Export resolutions
  static const Map<String, Map<String, int>> exportResolutions = {
    '720p': {'width': 1280, 'height': 720},
    '1080p': {'width': 1920, 'height': 1080},
  };

  // Aspect ratios
  static const Map<String, double> aspectRatios = {
    '9:16': 9 / 16, // Portrait (TikTok, Reels)
    '1:1': 1.0, // Square (Instagram)
    '16:9': 16 / 9, // Landscape (YouTube)
  };

  // Supported video formats
  static const List<String> supportedVideoFormats = [
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
    'm4v',
  ];

  // Supported audio formats
  static const List<String> supportedAudioFormats = [
    'mp3',
    'aac',
    'm4a',
    'wav',
    'ogg',
  ];

  // ========== PERFORMANCE FLAGS ==========

  /// Zero-copy preview mode (ENABLED)
  ///
  /// Clips are NOT exported during split.
  /// Instead, only timestamps are stored, allowing instant
  /// scrubbing and preview. Actual export happens only when
  /// user taps "EXPORT".
  ///
  /// Benefits:
  /// - Instant split/preview (no codec copy overhead)
  /// - Lower storage usage (no intermediate files)
  /// - Faster workflow for preview-heavy users
  ///
  /// **ENABLED** for maximum performance
  static const bool USE_ZERO_COPY_PREVIEW = true;

  /// Fallback to re-encoding (for debugging/compatibility)
  ///
  /// If set to true, uses slower re-encoding export mode
  /// instead of ultra-fast codec copy.
  ///
  /// Default: false (use codec copy for speed)
  static const bool FALLBACK_TO_REENCODE = false;

  // UI animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Splash screen duration
  static const Duration splashDuration = Duration(milliseconds: 2500);

  // Thumbnail dimensions
  static const int thumbnailWidth = 320;
  static const int thumbnailHeight = 180;

  // Storage keys
  static const String projectsBoxName = 'projects';
  static const String settingsBoxName = 'settings';

  // Padding and spacing
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 100.0;
}
