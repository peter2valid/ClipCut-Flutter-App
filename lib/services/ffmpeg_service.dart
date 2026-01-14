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

  /// ⚡⚡⚡ KEYFRAME SNAPPING for codec-copy compatibility
  static Future<Duration> snapToKeyframe(
    String videoPath,
    Duration position,
  ) async {
    try {
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

  /// Split video by duration and generate ClipModel list
  /// Duration options: 15, 30, 60, 90 seconds, or custom
  static Future<List<ClipModel>> splitVideo({
    required String videoPath,
    required int durationSeconds,
    Function(int current, int total)? onProgress,
  }) async {
    // Get video duration
    final totalDuration = await getVideoDuration(videoPath);
    final clipDuration = Duration(seconds: durationSeconds);

    final clips = <ClipModel>[];
    int currentStartMs = 0;
    int index = 0;

    while (currentStartMs < totalDuration.inMilliseconds) {
      int endMs = currentStartMs + clipDuration.inMilliseconds;
      if (endMs > totalDuration.inMilliseconds) {
        endMs = totalDuration.inMilliseconds;
      }

      // Only add clip if it has meaningful duration (at least 1 second)
      if (endMs - currentStartMs >= 1000) {
        final thumbnailsDir = await FileUtils.getThumbnailsDirectory();

        // Generate thumbnail at middle of clip
        final thumbnailTime = Duration(
          milliseconds: currentStartMs + (endMs - currentStartMs) ~/ 2,
        );

        final thumbnailPath = await generateThumbnail(
          videoPath: videoPath,
          timestamp: thumbnailTime,
          outputDir: thumbnailsDir.path,
        );

        clips.add(ClipModel(
          path: videoPath,
          start: Duration(milliseconds: currentStartMs),
          end: Duration(milliseconds: endMs),
          thumbnailPath: thumbnailPath,
          selected: true,
        ));

        index++;
        onProgress?.call(
            index, (totalDuration.inSeconds / durationSeconds).ceil());
      }

      currentStartMs = endMs;
    }

    return clips;
  }

  /// Clean up temporary clip files
  static Future<void> cleanupTempClips() async {
    await FileUtils.cleanupTempClips();
    await FileUtils.cleanupThumbnails();
  }

  /// Export a simple clip segment (P1 Enhancement)
  /// Extracts video segment without complex filters
  /// Returns true on success, false on failure
  static Future<bool> exportSimpleClip({
    required String videoPath,
    required Duration startTime,
    required Duration endTime,
    required String outputPath,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Ensure output directory exists
      final outputDir = outputPath.substring(0, outputPath.lastIndexOf('/'));
      await FileUtils.ensureDirectoryExists(outputDir);

      final duration = endTime - startTime;
      final startStr = DurationUtils.formatForFFmpeg(startTime);
      final durationStr = DurationUtils.formatForFFmpeg(duration);

      // Simple clip extraction with copy codec (fast)
      final command = '-ss $startStr -i "$videoPath" -t $durationStr '
          '-c:v libx264 -preset veryfast -crf 23 '
          '-c:a aac -b:a 128k '
          '-avoid_negative_ts make_zero '
          '-y "$outputPath"';

      // P0 FIX: Per-session progress callback
      int? sessionId;
      final session = await FFmpegKit.execute(command);
      sessionId = session.getSessionId();

      // Enable statistics for this session only
      if (onProgress != null) {
        FFmpegKitConfig.enableStatisticsCallback((statistics) {
          // Only process stats for this session
          if (statistics.getSessionId() == sessionId) {
            final timeMs = statistics.getTime().toDouble();
            final durationMs = duration.inMilliseconds.toDouble();
            if (durationMs > 0) {
              final progress = (timeMs / durationMs).clamp(0.0, 1.0);
              onProgress(progress);
            }
          }
        });
      }

      final returnCode = await session.getReturnCode();

      // Disable statistics callback
      FFmpegKitConfig.enableStatisticsCallback(null);

      if (ReturnCode.isSuccess(returnCode)) {
        return true;
      } else {
        final logs = await session.getOutput();
        print('[FFmpegService] Export failed: $logs');
        return false;
      }
    } catch (e) {
      print('[FFmpegService] exportSimpleClip error: $e');
      return false;
    }
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
            '[0:v]scale=$targetWidth:$targetHeight:force_original_aspect_ratio=decrease[main]');
        filters.add(
            '[0:v]scale=$targetWidth:$targetHeight:force_original_aspect_ratio=increase,crop=$targetWidth:$targetHeight,boxblur=20:5[bg]');
        filters.add('[bg][main]overlay=(W-w)/2:(H-h)/2[vout]');
        break;

      case BackgroundType.blackBars:
        // Black background with letterbox/pillarbox
        filters.add(
            '[0:v]scale=$targetWidth:$targetHeight:force_original_aspect_ratio=decrease,pad=$targetWidth:$targetHeight:(ow-iw)/2:(oh-ih)/2:black[vout]');
        break;

      case BackgroundType.solidColor:
        // Solid color background
        final color = clip.settings.backgroundColor ?? 0xFF000000;
        final colorHex = (color & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
        filters.add(
            '[0:v]scale=$targetWidth:$targetHeight:force_original_aspect_ratio=decrease,pad=$targetWidth:$targetHeight:(ow-iw)/2:(oh-ih)/2:0x$colorHex[vout]');
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
  /// Uses FileUtils.getExportDirectory for consistent behavior
  static Future<String> getExportDirectory() async {
    final dir = await FileUtils.getExportDirectory();
    return dir.path;
  }

  /// Cancel all running FFmpeg sessions
  static Future<void> cancelAll() async {
    await FFmpegKit.cancel();
  }

  /// ⚡ PERFORMANCE: Ultra-fast clip splitting using codec copy (10x faster)
  /// Runs in isolate to prevent UI blocking
  /// Returns list of output clip paths
  static Future<List<String>> splitSync(
    String path,
    int durationSeconds,
    Function(double)? onProgress,
  ) async {
    return await TaskRunner.run(() async {
      final List<String> outputs = [];
      final info = await FFprobeKit.getMediaInformation(path);
      final mediaInfo = info.getMediaInformation();
      final videoDuration = double.parse(mediaInfo?.getDuration() ?? '0');

      int index = 0;
      for (double start = 0; start < videoDuration; start += durationSeconds) {
        // Ensure output directory exists
        await Directory(FileUtils.tempClipsDir).create(recursive: true);

        final out = '${FileUtils.tempClipsDir}/clip_$index.mp4';
        final cmd = '-i "$path" -ss $start -t $durationSeconds -c copy "$out"';

        await FFmpegKit.execute(cmd);
        outputs.add(out);

        index++;
        onProgress?.call(start / videoDuration);
      }

      onProgress?.call(1.0);
      return outputs;
    });
  }

  /// ⚡ PERFORMANCE: Fast thumbnail generation with caching (lazy + low resolution)
  /// Generates 320px wide thumbnails for speed
  /// Checks cache before regenerating
  static Future<void> generateThumbnails(
    List<String> clips,
    Function(double)? onProgress,
  ) async {
    await TaskRunner.run(() async {
      // Ensure thumbnail directory exists
      await Directory(FileUtils.thumbDir).create(recursive: true);

      int index = 0;
      for (final clip in clips) {
        final out = '${FileUtils.thumbDir}/thumb_$index.jpg';

        // Check cache first
        if (!await FileUtils.thumbnailExists(out)) {
          await FFmpegKit.execute(
            '-i "$clip" -frames:v 1 -vf scale=320:-1 "$out"',
          );
        }

        index++;
        onProgress?.call(index / clips.length);
      }
    });
  }

  /// ⚡ PERFORMANCE: Fast export using codec copy (no re-encoding)
  /// Only use when no filters need to be applied.
  /// NOTE: No progress callback - codec copy is too fast for meaningful progress tracking
  static Future<bool> exportFastClip({
    required String inputPath,
    required Duration startTime,
    required Duration endTime,
    required String outputPath,
  }) async {
    try {
      // Ensure output directory exists
      final outputDir = outputPath.substring(0, outputPath.lastIndexOf('/'));
      await FileUtils.ensureDirectoryExists(outputDir);

      final duration = endTime - startTime;
      final startStr = DurationUtils.formatForFFmpeg(startTime);
      final durationStr = DurationUtils.formatForFFmpeg(duration);

      // Ultra-fast codec copy (no re-encoding)
      final command = '-ss $startStr -i "$inputPath" -t $durationStr '
          '-c copy '
          '-avoid_negative_ts make_zero '
          '-y "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return true;
      }
      return false;
    } catch (e) {
      print('[FFmpegService] exportFastClip error: $e');
      return false;
    }
  }

  /// ⚡⚡⚡ ULTRA-FAST: Export all clips using segment mode (10-20x faster)
  ///
  /// Uses a SINGLE FFmpeg call with `-f segment` to export all clips at once.
  /// This is dramatically faster than exporting clips one by one.
  ///
  /// Example:
  /// ```dart
  /// final result = await FFmpegService.exportWithSegmentation(
  ///   videoPath: '/path/to/video.mp4',
  ///   segmentDurationSeconds: 30,
  ///   outputDir: '/storage/emulated/0/Download/ClipCut',
  ///   onProgress: (progress) => print('Progress: ${progress * 100}%'),
  /// );
  ///
  /// if (result.success) {
  ///   print('Exported ${result.filePaths.length} clips');
  ///   for (final path in result.filePaths) {
  ///     print('  - $path');
  ///   }
  /// }
  /// ```
  ///
  /// [videoPath] - Input video file path
  /// [segmentDurationSeconds] - Duration of each segment in seconds (e.g. 15, 30, 60)
  /// [outputDir] - Directory to save exported clips
  /// [onProgress] - Optional progress callback (0.0 to 1.0)
  ///
  /// Returns [SegmentExportResult] with success status and list of exported file paths
  static Future<SegmentExportResult> exportWithSegmentation({
    required String videoPath,
    required int segmentDurationSeconds,
    required String outputDir,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Ensure output directory exists
      await Directory(outputDir).create(recursive: true);

      // Get video duration to estimate number of segments
      final durationSeconds = await getDurationSeconds(videoPath);
      final expectedSegments =
          (durationSeconds / segmentDurationSeconds).ceil();

      print('[FFmpegService] Starting segment export:');
      print('  Input: $videoPath');
      print('  Duration: ${durationSeconds.toStringAsFixed(1)}s');
      print('  Segment duration: ${segmentDurationSeconds}s');
      print('  Expected segments: $expectedSegments');
      print('  Output directory: $outputDir');

      // Build FFmpeg segment command
      // -f segment: Enable segment muxer
      // -segment_time: Duration of each segment
      // -reset_timestamps 1: Reset timestamps for each segment
      // -avoid_negative_ts make_zero: Ensure no negative timestamps
      // -c copy: Use codec copy (ultra-fast, no re-encoding)
      // -map 0: Copy all streams (video + audio)
      final outputPattern = '$outputDir/clip_%03d.mp4';
      final command = '-i "$videoPath" '
          '-map 0 '
          '-c copy '
          '-f segment '
          '-segment_time $segmentDurationSeconds '
          '-reset_timestamps 1 '
          '-avoid_negative_ts make_zero '
          '"$outputPattern"';

      print('[FFmpegService] Executing command: ffmpeg $command');

      // Track progress via FFmpeg statistics if callback provided
      int? sessionId;
      if (onProgress != null) {
        FFmpegKitConfig.enableStatisticsCallback((statistics) {
          if (sessionId != null && statistics.getSessionId() == sessionId) {
            final timeMs = statistics.getTime().toDouble();
            final durationMs = durationSeconds * 1000;
            if (durationMs > 0) {
              final progress = (timeMs / durationMs).clamp(0.0, 1.0);
              onProgress(progress);
            }
          }
        });
      }

      // Execute FFmpeg command
      final session = await FFmpegKit.execute(command);
      sessionId = session.getSessionId();
      final returnCode = await session.getReturnCode();

      // Disable statistics callback
      if (onProgress != null) {
        FFmpegKitConfig.enableStatisticsCallback(null);
      }

      // Check if FFmpeg succeeded
      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getAllLogsAsString();
        print('[FFmpegService] Segment export FAILED:');
        print(logs);
        return SegmentExportResult(
          success: false,
          filePaths: [],
          errorMessage: 'FFmpeg returned non-zero exit code: $returnCode',
        );
      }

      // Final progress update
      onProgress?.call(1.0);

      // Scan output directory and collect generated files
      final outputDirectory = Directory(outputDir);
      final files = await outputDirectory
          .list()
          .where((entity) =>
              entity is File &&
              entity.path.contains('clip_') &&
              entity.path.endsWith('.mp4'))
          .map((entity) => entity.path)
          .toList();

      // Sort files by name to ensure correct order (clip_000, clip_001, etc.)
      files.sort();

      print('[FFmpegService] Segment export SUCCESS:');
      print('  Generated ${files.length} clips');
      for (int i = 0; i < files.length; i++) {
        print('  [$i] ${files[i]}');
      }

      return SegmentExportResult(
        success: true,
        filePaths: files,
        errorMessage: null,
      );
    } catch (e) {
      print('[FFmpegService] exportWithSegmentation error: $e');
      return SegmentExportResult(
        success: false,
        filePaths: [],
        errorMessage: e.toString(),
      );
    }
  }
}

/// Result of segment-based export operation
class SegmentExportResult {
  final bool success;
  final List<String> filePaths;
  final String? errorMessage;

  const SegmentExportResult({
    required this.success,
    required this.filePaths,
    this.errorMessage,
  });
}
