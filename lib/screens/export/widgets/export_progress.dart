import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';

/// Export progress widget showing individual clip and overall progress
class ExportProgress extends StatelessWidget {
  final int currentClip;
  final int totalClips;
  final double clipProgress;
  final double overallProgress;
  final String? currentClipName;
  final VoidCallback? onCancel;

  const ExportProgress({
    super.key,
    required this.currentClip,
    required this.totalClips,
    required this.clipProgress,
    required this.overallProgress,
    this.currentClipName,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.movie_creation_outlined,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXPORTING',
                      style: AppTypography.labelLarge,
                    ),
                    Text(
                      'Clip $currentClip of $totalClips',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              // Cancel button
              if (onCancel != null)
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: onCancel,
                  tooltip: 'Cancel export',
                ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingL),

          // Current clip progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentClipName ?? 'Clip $currentClip',
                    style: AppTypography.labelMedium,
                  ),
                  Text(
                    '${(clipProgress * 100).toInt()}%',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingS),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: clipProgress,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingM),

          // Overall progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall progress',
                    style: AppTypography.caption,
                  ),
                  Text(
                    '${(overallProgress * 100).toInt()}%',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingXS),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: overallProgress,
                  minHeight: 4,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.accentDark),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingM),

          // Processing hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
              const SizedBox(width: AppConstants.paddingS),
              Text(
                'Please keep the app open',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
