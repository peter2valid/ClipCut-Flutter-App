import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'widgets/trim_slider.dart';
import 'widgets/aspect_ratio_picker.dart';
import 'widgets/background_picker.dart';
import 'widgets/audio_picker.dart';
import 'widgets/video_preview.dart';

/// Editor screen for editing individual clips
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  VideoClip? _clip;
  late ClipSettings _settings;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClip();
    });
  }

  void _loadClip() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final clipId = args['clipId'] as String?;
      if (clipId != null) {
        final project = ref.read(projectProvider).project;
        if (project != null) {
          final clip = project.getClipById(clipId);
          if (clip != null) {
            setState(() {
              _clip = clip;
              _settings = clip.settings;
            });
            return;
          }
        }
      }
    }

    // If no clip found, go back
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clip not found'),
          backgroundColor: AppColors.error,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _updateSettings(ClipSettings newSettings) {
    setState(() {
      _settings = newSettings;
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    if (_clip == null || !_hasChanges) return;

    setState(() => _isSaving = true);

    try {
      final updatedClip = _clip!.copyWith(settings: _settings);
      await ref.read(projectProvider.notifier).updateClip(updatedClip);

      if (mounted) {
        setState(() {
          _clip = updatedClip;
          _hasChanges = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes saved'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefault() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('RESET EDITS'),
        content: const Text('This will reset all edits to default. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('RESET'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _settings = ClipSettings.defaultSettings();
        _hasChanges = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('UNSAVED CHANGES'),
        content:
            const Text('You have unsaved changes. What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: const Text('DISCARD'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    switch (result) {
      case 'save':
        await _saveChanges();
        return true;
      case 'discard':
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider).project;

    if (_clip == null || project == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _onWillPop() && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.paddingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video preview
                      VideoPreview(
                        videoPath: project.sourceVideoPath,
                        startTime: _clip!.effectiveStartTime,
                        endTime: _clip!.effectiveEndTime,
                        aspectRatio: _settings.aspectRatio,
                        backgroundType: _settings.backgroundType,
                        backgroundColor: _settings.backgroundColor != null
                            ? Color(_settings.backgroundColor!)
                            : null,
                      ),

                      const SizedBox(height: AppConstants.paddingXL),

                      // Trim slider
                      TrimSlider(
                        clipDuration: _clip!.originalDuration,
                        trimStart: _settings.trimStart,
                        trimEnd: _settings.trimEnd,
                        onTrimStartChanged: (value) {
                          _updateSettings(_settings.copyWith(
                            trimStartMs: value.inMilliseconds,
                          ));
                        },
                        onTrimEndChanged: (value) {
                          _updateSettings(_settings.copyWith(
                            trimEndMs: value.inMilliseconds,
                          ));
                        },
                      ),

                      const SizedBox(height: AppConstants.paddingXL),

                      // Aspect ratio picker
                      AspectRatioPicker(
                        selectedRatio: _settings.aspectRatio,
                        onRatioChanged: (ratio) {
                          _updateSettings(_settings.copyWith(
                            aspectRatio: ratio,
                          ));
                        },
                      ),

                      const SizedBox(height: AppConstants.paddingXL),

                      // Background picker
                      BackgroundPicker(
                        selectedType: _settings.backgroundType,
                        selectedColor: _settings.backgroundColor != null
                            ? Color(_settings.backgroundColor!)
                            : null,
                        onTypeChanged: (type) {
                          _updateSettings(_settings.copyWith(
                            backgroundType: type,
                          ));
                        },
                        onColorChanged: (color) {
                          _updateSettings(_settings.copyWith(
                            backgroundType: BackgroundType.solidColor,
                            backgroundColor: color.value,
                          ));
                        },
                      ),

                      const SizedBox(height: AppConstants.paddingXL),

                      // Audio picker
                      AudioPicker(
                        selectedAudioPath: _settings.audioPath,
                        volume: _settings.audioVolume,
                        muteOriginal: _settings.muteOriginalAudio,
                        onAudioChanged: (path) {
                          _updateSettings(_settings.copyWith(
                            audioPath: path,
                          ));
                        },
                        onVolumeChanged: (volume) {
                          _updateSettings(_settings.copyWith(
                            audioVolume: volume,
                          ));
                        },
                        onMuteOriginalChanged: (mute) {
                          _updateSettings(_settings.copyWith(
                            muteOriginalAudio: mute,
                          ));
                        },
                      ),

                      const SizedBox(height: AppConstants.paddingXL),

                      // Reset button
                      if (_clip!.hasEdits || _hasChanges)
                        Center(
                          child: TextButton.icon(
                            onPressed: _resetToDefault,
                            icon: const Icon(
                              Icons.refresh_rounded,
                              size: 18,
                            ),
                            label: const Text('RESET TO DEFAULT'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                            ),
                          ),
                        ),

                      const SizedBox(height: AppConstants.paddingXL),
                    ],
                  ),
                ),
              ),

              // Bottom save bar
              if (_hasChanges) _buildSaveBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              if (await _onWillPop() && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),

          const SizedBox(width: AppConstants.paddingS),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CLIP #${_clip!.index + 1}',
                  style: AppTypography.headlineSmall,
                ),
                if (_hasChanges)
                  Text(
                    'Unsaved changes',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
          ),

          // Quick export button
          IconButton(
            icon: const Icon(Icons.save_alt_rounded),
            color: AppColors.accent,
            onPressed: () {
              // Navigate to export with just this clip
              Navigator.of(context).pushNamed(
                '/export',
                arguments: {
                  'singleClipId': _clip!.id,
                },
              );
            },
            tooltip: 'Export this clip',
          ),
        ],
      ),
    );
  }

  Widget _buildSaveBar() {
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
          Expanded(
            child: SecondaryButton(
              text: 'Discard',
              onPressed: () {
                setState(() {
                  _settings = _clip!.settings;
                  _hasChanges = false;
                });
              },
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: PrimaryButton(
              text: 'Save',
              isLoading: _isSaving,
              onPressed: _saveChanges,
            ),
          ),
        ],
      ),
    );
  }
}
