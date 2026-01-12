import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/models.dart';

/// Aspect ratio picker widget
class AspectRatioPicker extends StatelessWidget {
  final AspectRatioType selectedRatio;
  final ValueChanged<AspectRatioType> onRatioChanged;

  const AspectRatioPicker({
    super.key,
    required this.selectedRatio,
    required this.onRatioChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ASPECT RATIO',
          style: AppTypography.labelLarge,
        ),
        const SizedBox(height: AppConstants.paddingM),
        Row(
          children: [
            _buildRatioOption(
              ratio: AspectRatioType.portrait9x16,
              label: '9:16',
              icon: Icons.stay_current_portrait_rounded,
            ),
            const SizedBox(width: AppConstants.paddingM),
            _buildRatioOption(
              ratio: AspectRatioType.square1x1,
              label: '1:1',
              icon: Icons.crop_square_rounded,
            ),
            const SizedBox(width: AppConstants.paddingM),
            _buildRatioOption(
              ratio: AspectRatioType.landscape16x9,
              label: '16:9',
              icon: Icons.stay_current_landscape_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatioOption({
    required AspectRatioType ratio,
    required String label,
    required IconData icon,
  }) {
    final isSelected = selectedRatio == ratio;

    return Expanded(
      child: GestureDetector(
        onTap: () => onRatioChanged(ratio),
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
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? AppColors.textOnAccent
                    : AppColors.textSecondary,
              ),
              const SizedBox(height: AppConstants.paddingS),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected
                      ? AppColors.textOnAccent
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
