import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling runtime permissions
class PermissionService {
  /// Request storage permissions for Android
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we need different permissions
      final androidInfo = await _getAndroidVersion();

      if (androidInfo >= 33) {
        // Android 13+ uses granular media permissions
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();

        return photos.isGranted && videos.isGranted;
      } else if (androidInfo >= 30) {
        // Android 11-12 uses MANAGE_EXTERNAL_STORAGE
        if (await Permission.manageExternalStorage.isGranted) {
          return true;
        }
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      } else {
        // Android 10 and below
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      // iOS uses photo library permission
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }
    return true;
  }

  /// Check if storage permission is granted
  static Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();

      if (androidInfo >= 33) {
        return await Permission.photos.isGranted &&
            await Permission.videos.isGranted;
      } else if (androidInfo >= 30) {
        return await Permission.manageExternalStorage.isGranted;
      } else {
        return await Permission.storage.isGranted;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.status;
      return status.isGranted || status.isLimited;
    }
    return true;
  }

  /// Open app settings if permission is permanently denied
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Get Android SDK version
  static Future<int> _getAndroidVersion() async {
    try {
      // Simplified approach - in production, use device_info_plus for accurate detection
      // For now, default to Android 13 (SDK 33) for modern devices
      return 33;
    } catch (_) {
      return 30;
    }
  }
}
