import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/duration_utils.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'widgets/clip_thumbnail.dart';
import 'widgets/duration_selector.dart';

/// Clips list screen showing all generated clips with selection support
class ClipsListScreen extends ConsumerStatefulWidget {
  const ClipsListScreen({super.key});

  @override
  ConsumerState<ClipsListScreen> createState() => _ClipsListScreenState();
}

class _ClipsListScreenState extends ConsumerState<ClipsListScreen> {
  bool _isSelectionMode = false;
  bool _isGeneratingThumbnails = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize project if coming from import
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromArguments();
    });
  }

  /// Initialize project from navigation arguments (new import)
  Future<void> _initializeFromArguments() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final videoPath = args['videoPath'] as String?;
      final name = args['name'] as String?;
      final clipDuration = args['clipDuration'] as int?;

      if (videoPath != null && name != null && clipDuration != null) {
        await _createProject(videoPath, name, clipDuration);
      }
    }
  }

  /// Create a new project from imported video
  Future<void> _createProject(
      String videoPath, String name, int clipDuration) async {
    setState(() => _errorMessage = null);

    try {
      // Validate file exists
      final file = File(videoPath);
      if (!await file.exists()) {
        throw Exception(
            'Video file not found. It may have been moved or deleted.');
      }

      // Check file size (warn if very large)
      final fileSize = await file.length();
      if (fileSize > 1024 * 1024 * 1024 * 2) {
        // > 2GB
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Large file detected. Processing may take longer.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      // Create project
      await ref.read(projectProvider.notifier).createProjectFromVideo(
            videoPath: videoPath,
            name: name,
            clipDurationSeconds: clipDuration,
          );

      // Generate thumbnails in background
      _generateThumbnails();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Generate thumbnails for all clips
  Future<void> _generateThumbnails() async {
    if (_isGeneratingThumbnails) return;

    setState(() => _isGeneratingThumbnails = true);

    try {
      await ref.read(projectProvider.notifier).generateThumbnails();
    } catch (e) {
      debugPrint('Error generating thumbnails: $e');
      // Non-critical error - thumbnails are optional
    } finally {
      if (mounted) {
        setState(() => _isGeneratingThumbnails = false);
      }
    }
  }

  /// Change clip duration and regenerate clips
  Future<void> _changeDuration(int newDuration) async {
    final project = ref.read(projectProvider).project;
    if (project == null) return;

    // Confirm if clips have edits
    if (project.hasAnyEdits) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('CHANGE DURATION'),
          content: const Text(
            'This will regenerate all clips and your edits will be lost. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('CONTINUE'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    await ref.read(projectProvider.notifier).regenerateClips(newDuration);
  }

  /// Show custom duration input dialog
  Future<void> _showCustomDurationDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CUSTOM DURATION'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            hintText: 'Enter seconds (5-300)',
            suffixText: 'seconds',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null &&
                  value >= AppConstants.minCustomDuration &&
                  value <= AppConstants.maxCustomDuration) {
                Navigator.of(context).pop(value);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a value between 5 and 300'),
                  ),
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != null) {
      _changeDuration(result);
    }
  }

  /// Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        // Deselect all when exiting selection mode
        ref.read(projectProvider.notifier).updateProject(
              ref.read(projectProvider).project!.deselectAllClips(),
            );
      }
    });
  }

  /// Toggle clip selection
  void _toggleClipSelection(VideoClip clip) {
    ref.read(projectProvider.notifier).updateClip(clip.toggleSelection());
  }

  /// Select all clips
  void _selectAll() {
    ref.read(projectProvider.notifier).updateProject(
          ref.read(projectProvider).project!.selectAllClips(),
        );
  }

  /// Navigate to editor for a specific clip
  void _editClip(VideoClip clip) {
    Navigator.of(context).pushNamed(
      '/editor',
      arguments: {'clipId': clip.id},
    );
  }

  /// Navigate to export screen
  void _goToExport() {
    final project = ref.read(projectProvider).project;
    if (project == null) return;

    // Check if any clips are selected (in selection mode) or export all
    final hasSelection =
        _isSelectionMode && project.clips.any((c) => c.isSelected);

    Navigator.of(context).pushNamed(
      '/export',
      arguments: {
        'selectedOnly': hasSelection,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectProvider);
    final project = projectState.project;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingOverlay(
        isLoading: projectState.isLoading,
        message: 'Processing video...',
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(project),

              // Error message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  color: AppColors.error.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: AppConstants.paddingS),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.error),
                        onPressed: () => setState(() => _errorMessage = null),
                      ),
                    ],
                  ),
                ),

              // Project info
              if (project != null) ...[
                // Duration selector
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.paddingM,
                  ),
                  child: DurationSelector(
                    selectedDuration: project.clipDuration.inSeconds,
                    onDurationChanged: _changeDuration,
                    onCustomTap: _showCustomDurationDialog,
                  ),
                ),

                // Clips info bar
                _buildClipsInfoBar(project),

                // Clips grid
                Expanded(
                  child: _buildClipsGrid(project),
                ),

                // Bottom action bar
                _buildBottomBar(project),
              ],

              // Empty state
              if (project == null && !projectState.isLoading)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.video_library_outlined,
                          size: 64,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        Text(
                          'NO PROJECT LOADED',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingL),
                        SecondaryButton(
                          text: 'Go Back',
                          isExpanded: false,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(VideoProject? project) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),

          const SizedBox(width: AppConstants.paddingS),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project?.name ?? 'CLIPS',
                  style: AppTypography.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (project != null)
                  Text(
                    DurationUtils.formatHumanReadable(project.sourceDuration),
                    style: AppTypography.caption,
                  ),
              ],
            ),
          ),

          // Thumbnail loading indicator
          if (_isGeneratingThumbnails)
            const Padding(
              padding: EdgeInsets.only(right: AppConstants.paddingS),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
            ),

          // Selection mode toggle
          if (project != null && project.clips.isNotEmpty)
            IconButton(
              icon: Icon(
                _isSelectionMode
                    ? Icons.close_rounded
                    : Icons.checklist_rounded,
                color: _isSelectionMode
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
              onPressed: _toggleSelectionMode,
            ),
        ],
      ),
    );
  }

  Widget _buildClipsInfoBar(VideoProject project) {
    final selectedCount = project.selectedClipCount;
    final totalCount = project.clipCount;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: AppConstants.paddingS,
      ),
      child: Row(
        children: [
          Text(
            _isSelectionMode
                ? '$selectedCount of $totalCount selected'
                : '$totalCount clips',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          if (_isSelectionMode) ...[
            TextButton(
              onPressed: _selectAll,
              child: Text(
                selectedCount == totalCount ? 'DESELECT ALL' : 'SELECT ALL',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClipsGrid(VideoProject project) {
    if (project.clips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: AppColors.warning,
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              'NO CLIPS GENERATED',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              'Try a different clip duration',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 16 / 12, // Slightly taller than 16:9 for info
        crossAxisSpacing: AppConstants.paddingM,
        mainAxisSpacing: AppConstants.paddingM,
      ),
      itemCount: project.clips.length,
      itemBuilder: (context, index) {
        final clip = project.clips[index];
        return ClipThumbnail(
          clip: clip,
          isSelected: clip.isSelected,
          isEdited: clip.hasEdits,
          isExported: clip.isExported,
          onTap: _isSelectionMode
              ? () => _toggleClipSelection(clip)
              : () => _editClip(clip),
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() => _isSelectionMode = true);
              _toggleClipSelection(clip);
            }
          },
          onEditTap: _isSelectionMode ? null : () => _editClip(clip),
        );
      },
    );
  }

  Widget _buildBottomBar(VideoProject project) {
    final selectedCount = project.selectedClipCount;
    final hasSelection = _isSelectionMode && selectedCount > 0;

    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.paddingL,
        right: AppConstants.paddingL,
        bottom: AppConstants.paddingL + MediaQuery.of(context).padding.bottom,
        top: AppConstants.paddingM,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Export info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasSelection
                      ? 'EXPORT $selectedCount CLIPS'
                      : 'EXPORT ALL ${project.clipCount} CLIPS',
                  style: AppTypography.labelLarge,
                ),
                Text(
                  hasSelection
                      ? 'Selected clips will be saved'
                      : 'All clips will be saved to gallery',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),

          // Export button
          SizedBox(
            width: 120,
            child: PrimaryButton(
              text: 'Export',
              icon: Icons.save_alt_rounded,
              isExpanded: false,
              onPressed: project.clips.isNotEmpty ? _goToExport : null,
            ),
          ),
        ],
      ),
    );
  }
}
