import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';

/// Hero card for importing a new video
class ImportCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const ImportCard({
    super.key,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background gradient decoration
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.15),
                      AppColors.accent.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    child: isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                    AppColors.textOnAccent),
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.add_rounded,
                            size: 32,
                            color: AppColors.textOnAccent,
                          ),
                  ),

                  const Spacer(),

                  // Title
                  Text(
                    'NEW PROJECT',
                    style: AppTypography.headlineLarge,
                  ),

                  const SizedBox(height: AppConstants.paddingXS),

                  // Subtitle
                  Text(
                    'Import a video to start cutting',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingM),

                  // Supported formats
                  Wrap(
                    spacing: AppConstants.paddingS,
                    children: ['MP4', 'MOV', 'AVI', 'MKV']
                        .map((format) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                format,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

            // Tap indicator
            Positioned(
              right: AppConstants.paddingL,
              bottom: AppConstants.paddingL,
              child: Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.accent,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
