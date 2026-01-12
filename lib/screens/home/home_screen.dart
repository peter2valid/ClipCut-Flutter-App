import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/file_utils.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';
import 'widgets/import_card.dart';
import 'widgets/recent_project_tile.dart';

/// Home screen with import and recent projects
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isImporting = false;
  List<VideoProject> _recentProjects = [];

  @override
  void initState() {
    super.initState();
    _loadRecentProjects();
  }

  void _loadRecentProjects() {
    setState(() {
      _recentProjects = StorageService.getRecentProjects();
    });
  }

  Future<void> _importVideo() async {
    // Check permissions
    final hasPermission = await PermissionService.hasStoragePermission();
    if (!hasPermission) {
      final granted = await PermissionService.requestStoragePermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission is required to import videos'),
              action: SnackBarAction(
                label: 'SETTINGS',
                onPressed: PermissionService.openSettings,
              ),
            ),
          );
        }
        return;
      }
    }

    setState(() => _isImporting = true);

    try {
      final videoPath = await FilePickerService.pickVideo();

      if (videoPath != null && mounted) {
        // Show duration selection dialog
        final duration = await _showDurationDialog();

        if (duration != null && mounted) {
          // Navigate to clips screen and create project
          final fileName = FileUtils.getFileName(videoPath);

          Navigator.of(context).pushNamed(
            '/clips',
            arguments: {
              'videoPath': videoPath,
              'name': fileName,
              'clipDuration': duration,
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing video: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<int?> _showDurationDialog() async {
    int selectedDuration = AppConstants.defaultClipDuration;
    int? customDuration;

    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusL),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingL),

                  // Title
                  Text(
                    'CLIP DURATION',
                    style: AppTypography.headlineMedium,
                  ),

                  const SizedBox(height: AppConstants.paddingS),

                  Text(
                    'Choose how long each clip should be',
                    style: AppTypography.bodySmall,
                  ),

                  const SizedBox(height: AppConstants.paddingL),

                  // Duration chips
                  Wrap(
                    spacing: AppConstants.paddingS,
                    runSpacing: AppConstants.paddingS,
                    children: [
                      ...AppConstants.clipDurationPresets.map((duration) {
                        final isSelected = selectedDuration == duration &&
                            customDuration == null;
                        return ChoiceChip(
                          label: Text('${duration}s'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              selectedDuration = duration;
                              customDuration = null;
                            });
                          },
                          selectedColor: AppColors.accent,
                          backgroundColor: AppColors.surfaceLight,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.textOnAccent
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }),
                      ChoiceChip(
                        label: const Text('Custom'),
                        selected: customDuration != null,
                        onSelected: (selected) async {
                          if (selected) {
                            final custom = await _showCustomDurationDialog();
                            if (custom != null) {
                              setModalState(() {
                                customDuration = custom;
                                selectedDuration = custom;
                              });
                            }
                          }
                        },
                        selectedColor: AppColors.accent,
                        backgroundColor: AppColors.surfaceLight,
                        labelStyle: TextStyle(
                          color: customDuration != null
                              ? AppColors.textOnAccent
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  if (customDuration != null) ...[
                    const SizedBox(height: AppConstants.paddingM),
                    Text(
                      'Custom: ${customDuration}s',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppConstants.paddingL),

                  // Confirm button
                  PrimaryButton(
                    text: 'Continue',
                    onPressed: () {
                      Navigator.of(context)
                          .pop(customDuration ?? selectedDuration);
                    },
                  ),

                  const SizedBox(height: AppConstants.paddingM),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<int?> _showCustomDurationDialog() async {
    final controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('CUSTOM DURATION'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
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
        );
      },
    );
  }

  void _openProject(VideoProject project) {
    ref.read(projectProvider.notifier).loadProject(project);
    Navigator.of(context).pushNamed('/clips');
  }

  Future<void> _deleteProject(VideoProject project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DELETE PROJECT'),
        content: Text('Are you sure you want to delete "${project.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.deleteProject(project.id);
      _loadRecentProjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: Row(
                  children: [
                    // Logo
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusS),
                      ),
                      child: const Icon(
                        Icons.content_cut_rounded,
                        color: AppColors.textOnAccent,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: AppConstants.paddingM),

                    // Title
                    Text(
                      AppConstants.appName,
                      style: AppTypography.headlineLarge,
                    ),

                    const Spacer(),

                    // Settings button
                    IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        // TODO: Implement settings
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Import card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingL,
                ),
                child: ImportCard(
                  onTap: _importVideo,
                  isLoading: _isImporting,
                ),
              ),
            ),

            // Recent projects header
            if (_recentProjects.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingL),
                  child: SectionHeader(
                    title: 'Recent Projects',
                    subtitle: '${_recentProjects.length} projects',
                  ),
                ),
              ),

            // Recent projects list
            if (_recentProjects.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingL,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final project = _recentProjects[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppConstants.paddingM,
                        ),
                        child: RecentProjectTile(
                          project: project,
                          onTap: () => _openProject(project),
                          onDelete: () => _deleteProject(project),
                        ),
                      );
                    },
                    childCount: _recentProjects.length,
                  ),
                ),
              ),

            // Empty state
            if (_recentProjects.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingXL),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: AppConstants.paddingM),
                      Text(
                        'NO PROJECTS YET',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingS),
                      Text(
                        'Import a video to get started',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
