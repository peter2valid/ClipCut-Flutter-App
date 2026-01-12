/// Utility functions for Duration formatting and parsing
class DurationUtils {
  DurationUtils._();

  /// Format duration as MM:SS
  static String formatMinutesSeconds(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format duration as HH:MM:SS
  static String formatHoursMinutesSeconds(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format duration as human readable string (e.g., "2m 30s")
  static String formatHumanReadable(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return '${hours}h ${minutes}m';
    } else if (duration.inMinutes > 0) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds.remainder(60);
      return '${minutes}m ${seconds}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Format duration for FFmpeg (HH:MM:SS.mmm)
  static String formatForFFmpeg(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds = duration.inMilliseconds.remainder(1000);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(3, '0')}';
  }

  /// Parse duration from FFmpeg format (HH:MM:SS.mmm)
  static Duration parseFromFFmpeg(String durationString) {
    try {
      final parts = durationString.split(':');
      if (parts.length == 3) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final secondsParts = parts[2].split('.');
        final seconds = int.parse(secondsParts[0]);
        final milliseconds = secondsParts.length > 1
            ? int.parse(secondsParts[1].padRight(3, '0').substring(0, 3))
            : 0;
        return Duration(
          hours: hours,
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );
      }
    } catch (_) {}
    return Duration.zero;
  }

  /// Calculate number of clips for a given total duration and clip length
  static int calculateClipCount(Duration totalDuration, Duration clipDuration) {
    if (clipDuration.inSeconds <= 0) return 0;
    return (totalDuration.inMilliseconds / clipDuration.inMilliseconds).ceil();
  }
}
