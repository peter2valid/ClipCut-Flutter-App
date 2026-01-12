import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';
import '../services/services.dart';

/// State for the current project being edited
class ProjectState {
  final VideoProject? project;
  final bool isLoading;
  final String? error;

  const ProjectState({
    this.project,
    this.isLoading = false,
    this.error,
  });

  ProjectState copyWith({
    VideoProject? project,
    bool? isLoading,
    String? error,
  }) {
    return ProjectState(
      project: project ?? this.project,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing the current project
class ProjectNotifier extends StateNotifier<ProjectState> {
  ProjectNotifier() : super(const ProjectState());

  /// Set loading state
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading, error: null);
  }

  /// Set error state
  void setError(String error) {
    state = state.copyWith(isLoading: false, error: error);
  }

  /// Load or create a new project from video
  Future<void> createProjectFromVideo({
    required String videoPath,
    required String name,
    required int clipDurationSeconds,
  }) async {
    setLoading(true);

    try {
      // Get video metadata
      final metadata = await FFmpegService.getVideoMetadata(videoPath);
      final duration = metadata['duration'] as Duration;
      final width = metadata['width'] as int;
      final height = metadata['height'] as int;

      // Generate clip timestamps
      final clips = FFmpegService.generateClipTimestamps(
        totalDuration: duration,
        clipDuration: Duration(seconds: clipDurationSeconds),
      );

      // Create project
      final now = DateTime.now();
      final project = VideoProject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        sourceVideoPath: videoPath,
        sourceDurationMs: duration.inMilliseconds,
        sourceWidth: width,
        sourceHeight: height,
        clipDurationMs: clipDurationSeconds * 1000,
        clips: clips,
        createdAt: now,
        updatedAt: now,
      );

      // Save to storage
      await StorageService.saveProject(project);

      state = state.copyWith(project: project, isLoading: false);
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Load an existing project
  void loadProject(VideoProject project) {
    state = state.copyWith(project: project, error: null);
  }

  /// Update the current project
  Future<void> updateProject(VideoProject project) async {
    await StorageService.saveProject(project.touch());
    state = state.copyWith(project: project.touch());
  }

  /// Update a specific clip in the project
  Future<void> updateClip(VideoClip updatedClip) async {
    if (state.project == null) return;
    final newProject = state.project!.updateClip(updatedClip);
    await updateProject(newProject);
  }

  /// Generate thumbnails for all clips
  Future<void> generateThumbnails() async {
    if (state.project == null) return;

    final tempDir = await FFmpegService.getTempDirectory();
    final thumbnailDir = '$tempDir/thumbnails/${state.project!.id}';

    final updatedClips = await FFmpegService.generateClipThumbnails(
      videoPath: state.project!.sourceVideoPath,
      clips: state.project!.clips,
      outputDir: thumbnailDir,
    );

    final newProject = state.project!.copyWith(clips: updatedClips);
    await updateProject(newProject);
  }

  /// Regenerate clips with new duration
  Future<void> regenerateClips(int clipDurationSeconds) async {
    if (state.project == null) return;

    setLoading(true);

    try {
      final clips = FFmpegService.generateClipTimestamps(
        totalDuration: state.project!.sourceDuration,
        clipDuration: Duration(seconds: clipDurationSeconds),
      );

      final newProject = state.project!.copyWith(
        clipDurationMs: clipDurationSeconds * 1000,
        clips: clips,
      );

      await updateProject(newProject);
      state = state.copyWith(isLoading: false);

      // Generate thumbnails in background
      generateThumbnails();
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Clear the current project
  void clearProject() {
    state = const ProjectState();
  }
}

/// Provider for the current project state
final projectProvider =
    StateNotifierProvider<ProjectNotifier, ProjectState>((ref) {
  return ProjectNotifier();
});

/// Provider for recent projects list
final recentProjectsProvider = Provider<List<VideoProject>>((ref) {
  return StorageService.getRecentProjects();
});
