import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';

/// Duration selector widget with preset chips and custom option
class DurationSelector extends StatelessWidget {
  final int selectedDuration;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback? onCustomTap;

  const DurationSelector({
    super.key,
    required this.selectedDuration,
    required this.onDurationChanged,
    this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCustom =
        !AppConstants.clipDurationPresets.contains(selectedDuration);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
      child: Row(
        children: [
          // Preset duration chips
          ...AppConstants.clipDurationPresets.map((duration) {
            final isSelected = selectedDuration == duration && !isCustom;
            return Padding(
              padding: const EdgeInsets.only(right: AppConstants.paddingS),
              child: _buildChip(
                label: '${duration}s',
                isSelected: isSelected,
                onTap: () => onDurationChanged(duration),
              ),
            );
          }),

          // Custom chip
          _buildChip(
            label: isCustom ? '${selectedDuration}s' : 'Custom',
            isSelected: isCustom,
            onTap: onCustomTap,
            icon: Icons.tune_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.textOnAccent
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color:
                    isSelected ? AppColors.textOnAccent : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
