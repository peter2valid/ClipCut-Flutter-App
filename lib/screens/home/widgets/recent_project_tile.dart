import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/duration_utils.dart';
import '../../../data/models/models.dart';

/// Tile for displaying a recent project
class RecentProjectTile extends StatelessWidget {
  final VideoProject project;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const RecentProjectTile({
    super.key,
    required this.project,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.radiusM),
                bottomLeft: Radius.circular(AppConstants.radiusM),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: project.sourceThumbnailPath != null
                    ? Image.file(
                        File(project.sourceThumbnailPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Project name
                    Text(
                      project.name,
                      style: AppTypography.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Metadata
                    Text(
                      '${project.clipCount} clips • ${DurationUtils.formatHumanReadable(project.sourceDuration)}',
                      style: AppTypography.bodySmall,
                    ),

                    const SizedBox(height: 4),

                    // Date
                    Text(
                      _formatDate(project.updatedAt),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Progress indicator
                if (project.exportedClipCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: project.allClipsExported
                          ? AppColors.success.withOpacity(0.2)
                          : AppColors.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${project.exportedClipCount}/${project.clipCount}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: project.allClipsExported
                            ? AppColors.success
                            : AppColors.accent,
                      ),
                    ),
                  ),

                const Spacer(),

                // Delete button
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: onDelete,
                  ),
              ],
            ),

            const SizedBox(width: AppConstants.paddingS),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.video_library_outlined,
          color: AppColors.textMuted,
          size: 32,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
