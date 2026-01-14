import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
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

  /// Get the temporary clips directory
  /// Path: /data/data/com.clipcut.clipcut/cache/clips/
  static Future<Directory> getTempClipsDirectory() async {
    final cacheDir = await getTemporaryDirectory();
    final clipsDir = Directory('${cacheDir.path}/clips');

    if (!await clipsDir.exists()) {
      await clipsDir.create(recursive: true);
    }

    return clipsDir;
  }

  /// Get the thumbnails directory
  static Future<Directory> getThumbnailsDirectory() async {
    final cacheDir = await getTemporaryDirectory();
    final thumbsDir = Directory('${cacheDir.path}/thumbnails');

    if (!await thumbsDir.exists()) {
      await thumbsDir.create(recursive: true);
    }

    return thumbsDir;
  }

  /// Get the export directory
  ///
  /// **LOCKED TO DOWNLOADS FOLDER FOR SEGMENT EXPORT**
  ///
  /// Android: /storage/emulated/0/Download/ClipCut/
  /// iOS: Documents/ClipCut/
  ///
  /// This directory is used exclusively for exported clips.
  /// The single consistent path is required for segment-based export to work correctly.
  ///
  /// Throws an exception if the directory cannot be created or accessed.
  static Future<Directory> getExportDirectory() async {
    if (Platform.isAndroid) {
      try {
        final downloadDir = Directory('/storage/emulated/0/Download/ClipCut');

        // Create directory if it doesn't exist
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }

        // Test write permissions by creating a temp file
        final testFile = File('${downloadDir.path}/.test');
        await testFile.writeAsString('test');
        await testFile.delete();

        print('✓ Using Download directory: ${downloadDir.path}');
        return downloadDir;
      } catch (e) {
        print('❌ CRITICAL: Failed to create Download/ClipCut directory: $e');
        print('   Storage permission may be denied or storage is full.');

        // User-friendly error message
        throw Exception('ClipCut cannot write to storage.\n\n'
            'Please enable "Allow access to media" in Settings.\n\n'
            'If the problem persists, check if you have enough free storage space.');
      }
    } else {
      // iOS: use documents directory
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final exportDir = Directory('${docsDir.path}/ClipCut');

        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }

        print('✓ Using iOS Documents directory: ${exportDir.path}');
        return exportDir;
      } catch (e) {
        print('❌ CRITICAL: Failed to create iOS export directory: $e');
        throw Exception('Cannot create export directory: $e');
      }
    }
  }

  /// Clean up temporary clips
  static Future<void> cleanupTempClips() async {
    try {
      final clipsDir = await getTempClipsDirectory();
      if (await clipsDir.exists()) {
        await clipsDir.delete(recursive: true);
        await clipsDir.create(recursive: true);
      }
    } catch (e) {
      print('Failed to cleanup temp clips: $e');
    }
  }

  /// Clean up thumbnails
  static Future<void> cleanupThumbnails() async {
    try {
      final thumbsDir = await getThumbnailsDirectory();
      if (await thumbsDir.exists()) {
        await thumbsDir.delete(recursive: true);
        await thumbsDir.create(recursive: true);
      }
    } catch (e) {
      print('Failed to cleanup thumbnails: $e');
    }
  }

  /// Get file size in MB
  static Future<double> getFileSizeMB(String filePath) async {
    final bytes = await getFileSize(filePath);
    return bytes / (1024 * 1024);
  }

  /// Get temporary clips directory path (synchronous)
  static String get tempClipsDir =>
      '/data/data/com.clipcut.clipcut/cache/clips';

  /// Get thumbnails directory path (synchronous)
  static String get thumbDir =>
      '/data/data/com.clipcut.clipcut/cache/thumbnails';

  /// Check if a thumbnail exists in cache
  static Future<bool> thumbnailExists(String thumbnailPath) async {
    return await fileExists(thumbnailPath);
  }

  /// Get cached thumbnail path for a clip at specific timestamp
  static String getCachedThumbnailPath(int timestampMs) {
    return '$thumbDir/thumb_$timestampMs.jpg';
  }
}
