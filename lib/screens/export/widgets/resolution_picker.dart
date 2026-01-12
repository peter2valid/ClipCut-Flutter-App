import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/models.dart';

/// Resolution picker widget for export settings
class ResolutionPicker extends StatelessWidget {
  final ExportResolution selectedResolution;
  final ValueChanged<ExportResolution> onResolutionChanged;

  const ResolutionPicker({
    super.key,
    required this.selectedResolution,
    required this.onResolutionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RESOLUTION',
          style: AppTypography.labelLarge,
        ),
        const SizedBox(height: AppConstants.paddingM),
        Row(
          children: [
            _buildOption(
              resolution: ExportResolution.hd720p,
              label: '720p',
              sublabel: 'HD • Smaller file',
              icon: Icons.hd_outlined,
            ),
            const SizedBox(width: AppConstants.paddingM),
            _buildOption(
              resolution: ExportResolution.fullHd1080p,
              label: '1080p',
              sublabel: 'Full HD • Best quality',
              icon: Icons.high_quality_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOption({
    required ExportResolution resolution,
    required String label,
    required String sublabel,
    required IconData icon,
  }) {
    final isSelected = selectedResolution == resolution;

    return Expanded(
      child: GestureDetector(
        onTap: () => onResolutionChanged(resolution),
        child: AnimatedContainer(
          duration: AppConstants.animationFast,
          padding: const EdgeInsets.all(AppConstants.paddingM),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isSelected
                        ? AppColors.textOnAccent
                        : AppColors.textSecondary,
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      size: 20,
                      color: AppColors.textOnAccent,
                    ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingS),
              Text(
                label,
                style: AppTypography.headlineSmall.copyWith(
                  color: isSelected
                      ? AppColors.textOnAccent
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: AppTypography.caption.copyWith(
                  color: isSelected
                      ? AppColors.textOnAccent.withOpacity(0.8)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
