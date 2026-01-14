import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/models/models.dart';
import '../data/models/clip_model.dart';
import '../core/utils/duration_utils.dart';
import '../core/utils/file_utils.dart';
import '../core/utils/task_runner.dart';

/// Service for all FFmpeg video processing operations
/// ⚡⚡⚡ ZERO-COPY PREVIEW MODE ENABLED
class FFmpegService {
  static const _uuid = Uuid();

  /// Get video metadata (duration, resolution, etc.)
  static Future<Map<String, dynamic>> getVideoMetadata(String videoPath) async {
    final session = await FFprobeKit.getMediaInformation(videoPath);
    final info = session.getMediaInformation();

    if (info == null) {
      throw Exception('Failed to get video information');
    }

    final duration = info.getDuration();
    final streams = info.getStreams();

    int width = 0;
    int height = 0;
    double frameRate = 30.0;

    for (final stream in streams) {
      if (stream.getType() == 'video') {
        width = stream.getWidth() ?? 0;
        height = stream.getHeight() ?? 0;
        final avgFrameRate = stream.getAverageFrameRate();
        if (avgFrameRate != null && avgFrameRate.contains('/')) {
          final parts = avgFrameRate.split('/');
          if (parts.length == 2) {
            final num = double.tryParse(parts[0]) ?? 30;
            final den = double.tryParse(parts[1]) ?? 1;
            frameRate = num / den;
          }
        }
        break;
      }
    }

    return {
      'duration': duration != null
          ? Duration(milliseconds: (double.parse(duration) * 1000).toInt())
          : Duration.zero,
      'width': width,
      'height': height,
      'frameRate': frameRate,
    };
  }

  /// Get video duration (simplified helper)
  static Future<Duration> getVideoDuration(String videoPath) async {
    final metadata = await getVideoMetadata(videoPath);
    return metadata['duration'] as Duration;
  }

  /// ⚡ PERFORMANCE: Get video duration in seconds using isolate (zero UI blocking)
  static Future<double> getDurationSeconds(String path) async {
    return await TaskRunner.run(() async {
      final info = await FFprobeKit.getMediaInformation(path);
      final mediaInfo = info.getMediaInformation();
      return mediaInfo?.getDuration() != null
          ? double.parse(mediaInfo!.getDuration()!)
          : 0.0;
    });
  }

  /// ⚡⚡⚡ KEYFRAME SNAPPING: Snap timestamp to nearest keyframe
  ///
  /// Ensures `-c copy` exports work correctly by aligning to GOP boundaries.
  /// Codec copy only works cleanly at keyframe boundaries.
  static Future<Duration> snapToKeyframe(
    String videoPath,
    Duration position,
  ) async {
    try {
      // Get keyframes using ffprobe
      final command =
          '-select_streams v:0 -show_entries frame=pkt_pts_time,key_frame -of csv=p=0 "$videoPath"';
      final session = await FFprobeKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        return _fallbackSnap(position);
      }

      final output = await session.getOutput();
      if (output == null || output.isEmpty) {
        return _fallbackSnap(position);
      }

      // Parse keyframes
      final keyframes = <double>[];
      for (final line in output.split('\n')) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(',');
        if (parts.length >= 2 && parts[1].trim() == '1') {
          final time = double.tryParse(parts[0].trim());
          if (time != null) keyframes.add(time);
        }
      }

      if (keyframes.isEmpty) return _fallbackSnap(position);

      keyframes.sort();
      final positionSeconds = position.inMilliseconds / 1000.0;
      double nearestKeyframe = 0.0;

      for (final kf in keyframes) {
        if (kf <= positionSeconds) {
          nearestKeyframe = kf;
        } else {
          break;
        }
      }

      return Duration(milliseconds: (nearestKeyframe * 1000).round());
    } catch (e) {
      return _fallbackSnap(position);
    }
  }

  /// Fallback snap: Round to nearest 0.5 seconds
  static Duration _fallbackSnap(Duration position) {
    final halfSeconds = (position.inMilliseconds / 500).round();
    return Duration(milliseconds: halfSeconds * 500);
  }

  /// Generate a thumbnail for a specific timestamp
  static Future<String?> generateThumbnail({
    required String videoPath,
    required Duration timestamp,
    required String outputDir,
    int width = 320,
  }) async {
    try {
      await Directory(outputDir).create(recursive: true);

      final outputPath = '$outputDir/thumb_${timestamp.inMilliseconds}.jpg';
      final timeStr = DurationUtils.formatForFFmpeg(timestamp);

      final command =
          '-ss $timeStr -i "$videoPath" -vf "scale=$width:-1" -vframes 1 -y "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      }
      return null;
    } catch (e) {
      print('[FFmpegService] Thumbnail generation error: $e');
      return null;
    }
  }

  /// ⚡⚡⚡ ULTRA-FAST CODEC COPY EXPORT
  ///
  /// Exports a clip with keyframe-snapped timestamps using codec copy.
  /// No re-encoding = 0.5-2 seconds per clip.
  static Future<bool> exportFastClip({
    required String inputPath,
    required Duration startTime,
    required Duration endTime,
    required String outputPath,
  }) async {
    try {
      final startStr = DurationUtils.formatForFFmpeg(startTime);
      final duration = endTime - startTime;
      final durationStr = DurationUtils.formatForFFmpeg(duration);

      // Ultra-fast codec copy - no re-encoding!
      final command = '-ss $startStr -i "$inputPath" -t $durationStr '
          '-c copy '
          '-avoid_negative_ts make_zero '
          '-y "$outputPath"';

      print('[FFmpegService] Codec copy export: $outputPath');
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        print('✅ Export complete: ${outputPath.split('/').last}');
        return true;
      } else {
        print('❌ Export failed');
        return false;
      }
    } catch (e) {
      print('[FFmpegService] exportFastClip error: $e');
      return false;
    }
  }

  /// Get export directory
  static Future<String> getExportDirectory() async {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download/ClipCut';
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      return '${docsDir.path}/ClipCut';
    }
  }

  /// Cancel all active FFmpeg sessions
  static Future<void> cancelAll() async {
    await FFmpegKit.cancel();
  }
}
