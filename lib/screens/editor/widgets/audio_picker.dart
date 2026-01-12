import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/file_utils.dart';
import '../../../services/services.dart';

/// Audio picker widget for adding background music
class AudioPicker extends StatelessWidget {
  final String? selectedAudioPath;
  final double volume;
  final bool muteOriginal;
  final ValueChanged<String?> onAudioChanged;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<bool> onMuteOriginalChanged;

  const AudioPicker({
    super.key,
    this.selectedAudioPath,
    required this.volume,
    required this.muteOriginal,
    required this.onAudioChanged,
    required this.onVolumeChanged,
    required this.onMuteOriginalChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasAudio = selectedAudioPath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'AUDIO',
              style: AppTypography.labelLarge,
            ),
            if (hasAudio)
              TextButton(
                onPressed: () => onAudioChanged(null),
                child: Text(
                  'REMOVE',
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
          ],
        ),

        const SizedBox(height: AppConstants.paddingM),

        // Audio file selector
        GestureDetector(
          onTap: () => _pickAudio(context),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hasAudio
                        ? AppColors.accent.withOpacity(0.2)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Icon(
                    hasAudio ? Icons.music_note_rounded : Icons.add_rounded,
                    color: hasAudio ? AppColors.accent : AppColors.textMuted,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasAudio
                            ? FileUtils.getFileNameWithExtension(
                                selectedAudioPath!)
                            : 'Add background music',
                        style: AppTypography.labelMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        hasAudio ? 'Tap to change' : 'MP3, AAC, WAV supported',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),

        // Audio controls (only shown when audio is selected)
        if (hasAudio) ...[
          const SizedBox(height: AppConstants.paddingM),

          // Volume slider
          Row(
            children: [
              const Icon(
                Icons.volume_down_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              Expanded(
                child: Slider(
                  value: volume,
                  min: 0.0,
                  max: 1.0,
                  onChanged: onVolumeChanged,
                ),
              ),
              const Icon(
                Icons.volume_up_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppConstants.paddingS),
              SizedBox(
                width: 40,
                child: Text(
                  '${(volume * 100).round()}%',
                  style: AppTypography.caption,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),

          // Mute original audio toggle
          GestureDetector(
            onTap: () => onMuteOriginalChanged(!muteOriginal),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
                vertical: AppConstants.paddingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Row(
                children: [
                  Icon(
                    muteOriginal
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    size: 20,
                    color:
                        muteOriginal ? AppColors.accent : AppColors.textMuted,
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  Expanded(
                    child: Text(
                      'Mute original audio',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                  Switch(
                    value: muteOriginal,
                    onChanged: onMuteOriginalChanged,
                    activeColor: AppColors.accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickAudio(BuildContext context) async {
    try {
      final audioPath = await FilePickerService.pickAudio();

      if (audioPath != null) {
        // Validate file exists
        final file = File(audioPath);
        if (await file.exists()) {
          onAudioChanged(audioPath);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Audio file not found'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking audio: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting audio: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
