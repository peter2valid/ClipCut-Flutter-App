import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';
import 'widgets/resolution_picker.dart';

/// Export screen for exporting clips to device storage
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportSettings _settings = ExportSettings.balanced();
  bool _exportSelectedOnly = false;
  String? _singleClipId;
  List<String> _exportedPaths = [];
  bool _isComplete = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArguments();
    });
  }

  void _loadArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      setState(() {
        _exportSelectedOnly = args['selectedOnly'] == true;
        _singleClipId = args['singleClipId'] as String?;
      });
    }
  }

  List<VideoClip> get _clipsToExport {
    final project = ref.read(projectProvider).project;
    if (project == null) return [];

    if (_singleClipId != null) {
      final clip = project.getClipById(_singleClipId!);
      return clip != null ? [clip] : [];
    }

    if (_exportSelectedOnly) {
      return project.clips.where((c) => c.isSelected).toList();
    }

    return project.clips;
  }

  Future<void> _checkStorageSpace() async {
    // Storage space check - in production, use native code to get free space
    // For now, we'll proceed and handle errors during export
    try {
      if (Platform.isAndroid) {
        await FFmpegService.getExportDirectory();
        // Note: Getting free space requires native code
      }
    } catch (e) {
      debugPrint('Could not check storage space: $e');
    }
  }

  Future<void> _startExport() async {
    final project = ref.read(projectProvider).project;
    if (project == null) return;

    final clips = _clipsToExport;
    if (clips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No clips to export'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Request storage permission for export
    final hasPermission = await PermissionService.hasMediaPermission();
    if (!hasPermission) {
      final granted = await PermissionService.requestMediaPermissions();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Storage permission is required to export clips'),
            action: SnackBarAction(
              label: 'SETTINGS',
              onPressed: PermissionService.openSettings,
            ),
          ),
        );
        return;
      }
    }

    // Check storage space
    await _checkStorageSpace();

    setState(() {
      _errorMessage = null;
      _isComplete = false;
      _exportedPaths = [];
    });

    try {
      final paths = await ref.read(exportProvider.notifier).exportAllClips(
            settings: _settings,
            clipsToExport: clips,
          );

      // Trigger media scanner for exported files
      if (paths.isNotEmpty) {
        final scannedCount = await MediaScannerService.scanFiles(paths);
        debugPrint(
            'Media scanner: $scannedCount/${paths.length} files indexed');
      }

      if (mounted) {
        setState(() {
          _exportedPaths = paths;
          _isComplete = true;
        });

        if (paths.isEmpty) {
          setState(() => _errorMessage = 'Export failed. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Export error: $e';
          _isComplete = true;
        });
      }
    }
  }

  Future<void> _cancelExport() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CANCEL EXPORT'),
        content: const Text(
          'Are you sure you want to cancel? Already exported clips will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(exportProvider.notifier).cancelExport();
    }
  }

  void _openExportFolder() async {
    try {
      final exportDir = await FFmpegService.getExportDirectory();

      // Try to open the folder
      final result = await OpenFilex.open(exportDir);

      if (mounted) {
        if (result.type == ResultType.done) {
          // Success - no need to show message
        } else if (result.type == ResultType.fileNotFound) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Folder not found: $exportDir'),
              backgroundColor: AppColors.warning,
            ),
          );
        } else {
          // Show path as fallback if opening failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to: $exportDir'),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Could not open export folder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open folder'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportProvider);
    final project = ref.watch(projectProvider).project;
    final clips = _clipsToExport;

    return PopScope(
      canPop: !exportState.isExporting,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (exportState.isExporting) {
          await _cancelExport();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(exportState.isExporting),

              // Content
              Expanded(
                child: exportState.isExporting
                    ? _buildExportingState(exportState)
                    : _isComplete
                        ? _buildCompleteState()
                        : _buildSettingsState(project, clips),
              ),

              // Bottom action bar
              if (!exportState.isExporting && !_isComplete)
                _buildBottomBar(clips),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isExporting) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: Row(
        children: [
          // Back button (disabled during export)
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: isExporting ? null : () => Navigator.of(context).pop(),
          ),

          const SizedBox(width: AppConstants.paddingS),

          // Title
          Expanded(
            child: Text(
              'EXPORT',
              style: AppTypography.headlineSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsState(VideoProject? project, List<VideoClip> clips) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Export summary
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Center(
                    child: Text(
                      '${clips.length}',
                      style: AppTypography.headlineLarge.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clips.length == 1
                            ? 'CLIP TO EXPORT'
                            : 'CLIPS TO EXPORT',
                        style: AppTypography.labelLarge,
                      ),
                      Text(
                        _singleClipId != null
                            ? 'Single clip export'
                            : _exportSelectedOnly
                                ? 'Selected clips only'
                                : 'All clips',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (!_exportSelectedOnly && _singleClipId == null)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('CHANGE'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.paddingXL),

          // Resolution picker
          ResolutionPicker(
            selectedResolution: _settings.resolution,
            onResolutionChanged: (resolution) {
              setState(() {
                _settings = _settings.copyWith(resolution: resolution);
              });
            },
          ),

          const SizedBox(height: AppConstants.paddingXL),

          // Quality info
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OUTPUT SETTINGS',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingS),
                _buildInfoRow('Resolution', _settings.resolutionName),
                _buildInfoRow('Format', 'MP4 (H.264)'),
                _buildInfoRow(
                    'Video Bitrate', '${_settings.videoBitrate ~/ 1000} Mbps'),
                _buildInfoRow('Audio', '${_settings.audioBitrate} kbps AAC'),
                _buildInfoRow('Frame Rate', '${_settings.frameRate} fps'),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.paddingL),

          // Save location info
          Row(
            children: [
              const Icon(
                Icons.folder_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppConstants.paddingS),
              Expanded(
                child: FutureBuilder<String>(
                  future: FFmpegService.getExportDirectory(),
                  builder: (context, snapshot) {
                    return Text(
                      'Saving to: ${snapshot.data ?? 'Gallery'}',
                      style: AppTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildExportingState(ExportState exportState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Export icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.save_alt_rounded,
                size: 40,
                color: AppColors.accent,
              ),
            ),

            const SizedBox(height: AppConstants.paddingXL),

            // Progress text
            Text(
              exportState.progressText,
              style: AppTypography.headlineSmall,
            ),

            const SizedBox(height: AppConstants.paddingM),

            // Overall progress bar
            SizedBox(
              width: 280,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: exportState.overallProgress,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Text(
                    '${exportState.progressPercent}%',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingXL),

            // Cancel button
            TextButton.icon(
              onPressed: _cancelExport,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('CANCEL'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteState() {
    final hasError = _errorMessage != null;
    final successCount = _exportedPaths.length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: hasError
                    ? AppColors.error.withOpacity(0.2)
                    : AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                hasError ? Icons.error_outline_rounded : Icons.check_rounded,
                size: 40,
                color: hasError ? AppColors.error : AppColors.success,
              ),
            ),

            const SizedBox(height: AppConstants.paddingL),

            // Status title
            Text(
              hasError ? 'EXPORT FAILED' : 'EXPORT COMPLETE',
              style: AppTypography.headlineLarge,
            ),

            const SizedBox(height: AppConstants.paddingS),

            // Status message
            Text(
              hasError
                  ? _errorMessage!
                  : '$successCount clip${successCount == 1 ? '' : 's'} saved to gallery',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppConstants.paddingXL),

            // Actions
            if (!hasError) ...[
              PrimaryButton(
                text: 'View in Gallery',
                icon: Icons.photo_library_outlined,
                onPressed: _openExportFolder,
              ),
              const SizedBox(height: AppConstants.paddingM),
            ],

            SecondaryButton(
              text: hasError ? 'Try Again' : 'Done',
              onPressed: () {
                if (hasError) {
                  setState(() {
                    _isComplete = false;
                    _errorMessage = null;
                  });
                } else {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(List<VideoClip> clips) {
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
      child: PrimaryButton(
        text: 'Start Export',
        icon: Icons.save_alt_rounded,
        onPressed: clips.isNotEmpty ? _startExport : null,
      ),
    );
  }
}
