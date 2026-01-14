import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling runtime permissions
class PermissionService {
  /// Request media permissions for videos, photos, and storage
  ///
  /// This method handles permission requests across different Android versions:
  /// - Uses granular media permissions (videos, photos) with storage fallback
  /// - Returns true if any permission is granted (allows flexible access)
  static Future<bool> requestMediaPermissions() async {
    if (Platform.isAndroid) {
      // Request multiple permissions at once
      final result = await [
        Permission.videos,
        Permission.photos,
        Permission.storage,
      ].request();

      // Return true if any permission is granted
      return result.values.any((status) => status.isGranted);
    } else if (Platform.isIOS) {
      // iOS uses photo library permission
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }
    return true;
  }

  /// Check if media permissions are granted
  ///
  /// Returns true if any of the media permissions (videos, photos, storage) are granted
  static Future<bool> hasMediaPermission() async {
    if (Platform.isAndroid) {
      final videosGranted = await Permission.videos.isGranted;
      final photosGranted = await Permission.photos.isGranted;
      final storageGranted = await Permission.storage.isGranted;

      return videosGranted || photosGranted || storageGranted;
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

  // Legacy method name for backwards compatibility
  @Deprecated('Use requestMediaPermissions() instead')
  static Future<bool> requestStoragePermission() async {
    return requestMediaPermissions();
  }

  // Legacy method name for backwards compatibility
  @Deprecated('Use hasMediaPermission() instead')
  static Future<bool> hasStoragePermission() async {
    return hasMediaPermission();
  }
}
