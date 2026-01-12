import 'dart:io';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/models/models.dart';
import '../core/utils/duration_utils.dart';

/// Service for all FFmpeg video processing operations
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

  /// Split video into clips based on duration
  /// Returns a list of VideoClip objects with timestamps
  static List<VideoClip> generateClipTimestamps({
    required Duration totalDuration,
    required Duration clipDuration,
  }) {
    final clips = <VideoClip>[];
    int currentStartMs = 0;
    int index = 0;

    while (currentStartMs < totalDuration.inMilliseconds) {
      int endMs = currentStartMs + clipDuration.inMilliseconds;
      if (endMs > totalDuration.inMilliseconds) {
        endMs = totalDuration.inMilliseconds;
      }

      // Only add clip if it has meaningful duration (at least 1 second)
      if (endMs - currentStartMs >= 1000) {
        clips.add(VideoClip(
          id: _uuid.v4(),
          index: index,
          startTimeMs: currentStartMs,
          endTimeMs: endMs,
          settings: ClipSettings.defaultSettings(),
        ));
        index++;
      }

      currentStartMs = endMs;
    }

    return clips;
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
          '-ss $timeStr -i "$videoPath" -vframes 1 -vf scale=$width:-1 -y "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      }
      return null;
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  /// Generate thumbnails for all clips
  static Future<List<VideoClip>> generateClipThumbnails({
    required String videoPath,
    required List<VideoClip> clips,
    required String outputDir,
    void Function(int current, int total)? onProgress,
  }) async {
    final updatedClips = <VideoClip>[];

    for (int i = 0; i < clips.length; i++) {
      final clip = clips[i];
      onProgress?.call(i + 1, clips.length);

      // Generate thumbnail at 1/3 of the clip duration
      final thumbnailTime = Duration(
        milliseconds:
            clip.startTimeMs + (clip.endTimeMs - clip.startTimeMs) ~/ 3,
      );

      final thumbnailPath = await generateThumbnail(
        videoPath: videoPath,
        timestamp: thumbnailTime,
        outputDir: outputDir,
      );

      updatedClips.add(clip.copyWith(thumbnailPath: thumbnailPath));
    }

    return updatedClips;
  }

  /// Export a single clip with all settings applied
  static Future<String?> exportClip({
    required String inputPath,
    required VideoClip clip,
    required ExportSettings settings,
    required String outputDir,
    void Function(double progress)? onProgress,
  }) async {
    try {
      await Directory(outputDir).create(recursive: true);

      final outputPath =
          '$outputDir/clip_${clip.index + 1}_${DateTime.now().millisecondsSinceEpoch}.${settings.outputFormat}';

      // Calculate effective timestamps
      final startMs = clip.startTimeMs + clip.settings.trimStartMs;
      final endMs = clip.endTimeMs + clip.settings.trimEndMs;
      final durationMs = endMs - startMs;

      final startTime =
          DurationUtils.formatForFFmpeg(Duration(milliseconds: startMs));
      final durationStr =
          DurationUtils.formatForFFmpeg(Duration(milliseconds: durationMs));

      // Build filter complex based on settings
      final filterComplex = _buildFilterComplex(
        clip: clip,
        settings: settings,
      );

      // Build the full command
      String command = '-ss $startTime -i "$inputPath" -t $durationStr';

      // Add audio input if specified
      if (clip.settings.audioPath != null) {
        command += ' -i "${clip.settings.audioPath}"';
      }

      // Add filter complex
      command += ' -filter_complex "$filterComplex"';

      // Map outputs
      command += ' -map "[vout]"';
      if (clip.settings.audioPath != null) {
        command += ' -map "[aout]"';
      } else if (!clip.settings.muteOriginalAudio) {
        command += ' -map 0:a?';
      }

      // Output settings
      command += ' -c:v libx264 -preset medium -crf 23';
      command += ' -b:v ${settings.videoBitrate}k';
      command += ' -c:a aac -b:a ${settings.audioBitrate}k';
      command += ' -r ${settings.frameRate}';
      command += ' -movflags +faststart';
      command += ' -y "$outputPath"';

      // Enable statistics for progress
      FFmpegKitConfig.enableStatisticsCallback((statistics) {
        if (onProgress != null && durationMs > 0) {
          final timeMs = statistics.getTime().toDouble();
          final progress = (timeMs / durationMs).clamp(0.0, 1.0);
          onProgress(progress);
        }
      });

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        final logs = await session.getAllLogsAsString();
        print('FFmpeg export failed: $logs');
        return null;
      }
    } catch (e) {
      print('Error exporting clip: $e');
      return null;
    }
  }

  /// Build FFmpeg filter complex string
  static String _buildFilterComplex({
    required VideoClip clip,
    required ExportSettings settings,
  }) {
    final filters = <String>[];
    final aspectRatio = clip.settings.aspectRatioValue;
    final outputWidth = settings.width;
    final outputHeight = settings.height;

    // Calculate target dimensions based on aspect ratio
    int targetWidth, targetHeight;
    if (aspectRatio < 1) {
      // Portrait (9:16)
      targetHeight = outputHeight;
      targetWidth = (outputHeight * aspectRatio).round();
    } else if (aspectRatio > 1) {
      // Landscape (16:9)
      targetWidth = outputWidth;
      targetHeight = (outputWidth / aspectRatio).round();
    } else {
      // Square (1:1)
      targetWidth = outputHeight; // Use height for square to fit
      targetHeight = outputHeight;
    }

    // Ensure even dimensions
    targetWidth = (targetWidth ~/ 2) * 2;
    targetHeight = (targetHeight ~/ 2) * 2;

    // Build background based on type
    switch (clip.settings.backgroundType) {
      case BackgroundType.blur:
        // Blurred background with main video on top
        filters.add(
            '[0:v]scale=${targetWidth}:${targetHeight}:force_original_aspect_ratio=decrease[main]');
        filters.add(
            '[0:v]scale=${targetWidth}:${targetHeight}:force_original_aspect_ratio=increase,crop=${targetWidth}:${targetHeight},boxblur=20:5[bg]');
        filters.add('[bg][main]overlay=(W-w)/2:(H-h)/2[vout]');
        break;

      case BackgroundType.blackBars:
        // Black background with letterbox/pillarbox
        filters.add(
            '[0:v]scale=${targetWidth}:${targetHeight}:force_original_aspect_ratio=decrease,pad=${targetWidth}:${targetHeight}:(ow-iw)/2:(oh-ih)/2:black[vout]');
        break;

      case BackgroundType.solidColor:
        // Solid color background
        final color = clip.settings.backgroundColor ?? 0xFF000000;
        final colorHex = (color & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
        filters.add(
            '[0:v]scale=${targetWidth}:${targetHeight}:force_original_aspect_ratio=decrease,pad=${targetWidth}:${targetHeight}:(ow-iw)/2:(oh-ih)/2:0x$colorHex[vout]');
        break;
    }

    // Build audio filter if needed
    if (clip.settings.audioPath != null) {
      if (clip.settings.muteOriginalAudio) {
        filters.add('[1:a]volume=${clip.settings.audioVolume}[aout]');
      } else {
        filters.add('[0:a][1:a]amix=inputs=2:duration=first[aout]');
      }
    }

    return filters.join(';');
  }

  /// Batch export multiple clips
  static Future<List<String>> exportClips({
    required String inputPath,
    required List<VideoClip> clips,
    required ExportSettings settings,
    required String outputDir,
    void Function(int current, int total, double clipProgress)? onProgress,
  }) async {
    final exportedPaths = <String>[];

    for (int i = 0; i < clips.length; i++) {
      final clip = clips[i];

      final outputPath = await exportClip(
        inputPath: inputPath,
        clip: clip,
        settings: settings,
        outputDir: outputDir,
        onProgress: (progress) {
          onProgress?.call(i + 1, clips.length, progress);
        },
      );

      if (outputPath != null) {
        exportedPaths.add(outputPath);
      }
    }

    return exportedPaths;
  }

  /// Get app's cache directory for temporary files
  static Future<String> getTempDirectory() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/clipcut_temp';
  }

  /// Get app's documents directory for exports
  static Future<String> getExportDirectory() async {
    if (Platform.isAndroid) {
      // Use Download folder on Android
      final dir = Directory('/storage/emulated/0/Download/ClipCut');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    } else {
      // Use Documents on iOS
      final dir = await getApplicationDocumentsDirectory();
      return '${dir.path}/ClipCut';
    }
  }

  /// Cancel all running FFmpeg sessions
  static Future<void> cancelAll() async {
    await FFmpegKit.cancel();
  }
}
