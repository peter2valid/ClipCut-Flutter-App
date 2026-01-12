import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/models.dart';

/// Background picker widget for choosing background type and color
class BackgroundPicker extends StatelessWidget {
  final BackgroundType selectedType;
  final Color? selectedColor;
  final ValueChanged<BackgroundType> onTypeChanged;
  final ValueChanged<Color> onColorChanged;

  const BackgroundPicker({
    super.key,
    required this.selectedType,
    this.selectedColor,
    required this.onTypeChanged,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BACKGROUND',
          style: AppTypography.labelLarge,
        ),
        const SizedBox(height: AppConstants.paddingM),
        Row(
          children: [
            _buildTypeOption(
              context: context,
              type: BackgroundType.blur,
              label: 'Blur',
              icon: Icons.blur_on_rounded,
            ),
            const SizedBox(width: AppConstants.paddingM),
            _buildTypeOption(
              context: context,
              type: BackgroundType.blackBars,
              label: 'Black',
              icon: Icons.crop_rounded,
            ),
            const SizedBox(width: AppConstants.paddingM),
            _buildColorOption(context),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required BuildContext context,
    required BackgroundType type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTypeChanged(type),
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

  Widget _buildColorOption(BuildContext context) {
    final isSelected = selectedType == BackgroundType.solidColor;
    final color = selectedColor ?? Colors.black;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          onTypeChanged(BackgroundType.solidColor);
          _showColorPicker(context);
        },
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
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.textOnAccent : AppColors.border,
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingS),
              Text(
                'Color',
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

  void _showColorPicker(BuildContext context) {
    Color pickerColor = selectedColor ?? Colors.black;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PICK COLOR'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            enableAlpha: false,
            displayThumbColor: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              onColorChanged(pickerColor);
              Navigator.of(context).pop();
            },
            child: const Text('SELECT'),
          ),
        ],
      ),
    );
  }
}
