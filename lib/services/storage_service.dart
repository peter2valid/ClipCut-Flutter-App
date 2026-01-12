import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/models.dart';
import '../core/constants/app_constants.dart';

/// Service for managing local storage using Hive
class StorageService {
  static Box<VideoProject>? _projectsBox;

  /// Initialize Hive and register adapters
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(VideoProjectAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(VideoClipAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ClipSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AspectRatioTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(BackgroundTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(ExportResolutionAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(ExportSettingsAdapter());
    }

    // Open boxes
    _projectsBox =
        await Hive.openBox<VideoProject>(AppConstants.projectsBoxName);
  }

  /// Get all saved projects
  static List<VideoProject> getAllProjects() {
    if (_projectsBox == null) return [];
    return _projectsBox!.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Most recent first
  }

  /// Get a project by ID
  static VideoProject? getProject(String id) {
    if (_projectsBox == null) return null;
    try {
      return _projectsBox!.values.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Save a project
  static Future<void> saveProject(VideoProject project) async {
    if (_projectsBox == null) return;
    await _projectsBox!.put(project.id, project);
  }

  /// Delete a project
  static Future<void> deleteProject(String id) async {
    if (_projectsBox == null) return;
    await _projectsBox!.delete(id);
  }

  /// Check if a project exists
  static bool projectExists(String id) {
    if (_projectsBox == null) return false;
    return _projectsBox!.containsKey(id);
  }

  /// Get recent projects (limited count)
  static List<VideoProject> getRecentProjects({int limit = 10}) {
    final all = getAllProjects();
    return all.take(limit).toList();
  }

  /// Clear all projects
  static Future<void> clearAllProjects() async {
    if (_projectsBox == null) return;
    await _projectsBox!.clear();
  }

  /// Close all Hive boxes
  static Future<void> close() async {
    await _projectsBox?.close();
  }
}
