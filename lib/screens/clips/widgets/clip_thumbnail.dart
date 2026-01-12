import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/duration_utils.dart';
import '../../../data/models/models.dart';

/// Thumbnail widget for displaying a clip preview
class ClipThumbnail extends StatelessWidget {
  final VideoClip clip;
  final bool isSelected;
  final bool isEdited;
  final bool isExported;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEditTap;

  const ClipThumbnail({
    super.key,
    required this.clip,
    this.isSelected = false,
    this.isEdited = false,
    this.isExported = false,
    this.onTap,
    this.onLongPress,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Thumbnail image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusM - 2),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildThumbnailImage(),
              ),
            ),

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM - 2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Selection checkbox
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: AppColors.textOnAccent,
                  ),
                ),
              ),

            // Clip number badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${clip.index + 1}',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 14,
                    letterSpacing: 1,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            // Status badges (edited/exported)
            if (isEdited || isExported)
              Positioned(
                top: 8,
                right: isSelected ? 40 : 8,
                child: Row(
                  children: [
                    if (isEdited)
                      _buildStatusBadge(
                        icon: Icons.edit,
                        color: AppColors.accent,
                      ),
                    if (isExported) ...[
                      if (isEdited) const SizedBox(width: 4),
                      _buildStatusBadge(
                        icon: Icons.check_circle,
                        color: AppColors.success,
                      ),
                    ],
                  ],
                ),
              ),

            // Bottom info
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Row(
                children: [
                  // Duration
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DurationUtils.formatMinutesSeconds(
                              clip.originalDuration),
                          style: AppTypography.labelMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${DurationUtils.formatMinutesSeconds(clip.startTime)} - ${DurationUtils.formatMinutesSeconds(clip.endTime)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Edit button
                  if (onEditTap != null)
                    GestureDetector(
                      onTap: onEditTap,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailImage() {
    // Safely load thumbnail with error handling
    if (clip.thumbnailPath != null) {
      final file = File(clip.thumbnailPath!);
      // Check synchronously for performance (thumbnail should exist)
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Log error and show placeholder
            debugPrint('Error loading thumbnail: $error');
            return _buildPlaceholder();
          },
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedSwitcher(
              duration: AppConstants.animationFast,
              child: frame != null ? child : _buildPlaceholder(),
            );
          },
        );
      }
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.videocam_outlined,
          size: 40,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildStatusBadge({required IconData icon, required Color color}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 14,
        color: color,
      ),
    );
  }
}
