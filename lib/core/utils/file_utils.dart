import 'dart:io';
import 'package:path/path.dart' as path;
import '../constants/app_constants.dart';

/// Utility functions for file handling
class FileUtils {
  FileUtils._();

  /// Get file extension without the dot
  static String getExtension(String filePath) {
    return path.extension(filePath).toLowerCase().replaceAll('.', '');
  }

  /// Check if file is a supported video format
  static bool isSupportedVideo(String filePath) {
    final ext = getExtension(filePath);
    return AppConstants.supportedVideoFormats.contains(ext);
  }

  /// Check if file is a supported audio format
  static bool isSupportedAudio(String filePath) {
    final ext = getExtension(filePath);
    return AppConstants.supportedAudioFormats.contains(ext);
  }

  /// Get file name without extension
  static String getFileName(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  /// Get file name with extension
  static String getFileNameWithExtension(String filePath) {
    return path.basename(filePath);
  }

  /// Format file size to human readable string
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Get file size
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (_) {}
    return 0;
  }

  /// Check if file exists
  static Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (_) {
      return false;
    }
  }

  /// Delete file if exists
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Create directory if not exists
  static Future<Directory> ensureDirectoryExists(String dirPath) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  /// Generate unique output filename
  static String generateOutputFileName({
    required String baseName,
    required int index,
    String extension = 'mp4',
  }) {
    return '${baseName}_clip_${(index + 1).toString().padLeft(3, '0')}.$extension';
  }
}
