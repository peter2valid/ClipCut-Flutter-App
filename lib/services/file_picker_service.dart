import 'package:file_picker/file_picker.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/file_utils.dart';

/// Service for picking videos and audio files from device storage
class FilePickerService {
  /// Pick a video file from device storage
  static Future<String?> pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          // Validate file type
          if (FileUtils.isSupportedVideo(file.path!)) {
            return file.path;
          }
        }
      }
      return null;
    } catch (e) {
      print('Error picking video: $e');
      return null;
    }
  }

  /// Pick an audio file from device storage
  static Future<String?> pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.supportedAudioFormats,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          return file.path;
        }
      }
      return null;
    } catch (e) {
      print('Error picking audio: $e');
      return null;
    }
  }

  /// Pick multiple video files
  static Future<List<String>> pickMultipleVideos() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );

      if (result != null) {
        return result.files
            .where((f) => f.path != null && FileUtils.isSupportedVideo(f.path!))
            .map((f) => f.path!)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error picking videos: $e');
      return [];
    }
  }

  /// Clear the file picker cache
  static Future<void> clearCache() async {
    try {
      await FilePicker.platform.clearTemporaryFiles();
    } catch (e) {
      print('Error clearing file picker cache: $e');
    }
  }
}
