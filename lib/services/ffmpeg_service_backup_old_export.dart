import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../data/models/models.dart';
import '../core/utils/duration_utils.dart';

/// BACKUP: Old per-clip export methods
///
/// This file contains the original export implementation that exported
/// each clip individually. This was replaced with segment-based export
/// for 10-20x performance improvement.
///
/// Kept for reference and potential fallback if segment mode has issues.
///
/// ⚠️ DO NOT USE IN PRODUCTION - Use FFmpegService.exportWithSegmentation() instead
class FFmpegServiceBackup {
  /// [DEPRECATED] Export a single clip with all settings applied
  ///
  /// This method exports clips one at a time, which is slow for batch operations.
  /// Use FFmpegService.exportWithSegmentation() for batch exports instead.
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

  /// [DEPRECATED] Batch export multiple clips
  ///
  /// This method loops through clips and exports them one by one.
  /// Use FFmpegService.exportWithSegmentation() instead for much faster batch export.
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
}
