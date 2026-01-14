import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/clip_provider.dart';

/// Simple clips list screen with checkbox selection
/// Uses ClipModel and ClipProvider
class SimpleClipsScreen extends ConsumerWidget {
  const SimpleClipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clipsState = ref.watch(clipsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('CLIPS'),
        actions: [
          if (clipsState.clips.isNotEmpty)
            TextButton(
              onPressed: () {
                final allSelected = clipsState.clips.every((c) => c.selected);
                if (allSelected) {
                  ref.read(clipsProvider.notifier).deselectAll();
                } else {
                  ref.read(clipsProvider.notifier).selectAll();
                }
              },
              child: Text(
                clipsState.clips.every((c) => c.selected)
                    ? 'DESELECT ALL'
                    : 'SELECT ALL',
                style: const TextStyle(color: Color(0xFF6366F1)),
              ),
            ),
        ],
      ),
      body: clipsState.isLoading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.video_library,
                      size: 64,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(height: 32),

                    // Import Progress
                    _ProgressRow(
                      label: 'Importing',
                      progress: clipsState.importProgress,
                    ),
                    const SizedBox(height: 16),

                    // Split Progress
                    _ProgressRow(
                      label: 'Splitting',
                      progress: clipsState.splitProgress,
                    ),
                    const SizedBox(height: 16),

                    // Thumbnail Progress
                    _ProgressRow(
                      label: 'Thumbnails',
                      progress: clipsState.thumbnailProgress,
                    ),
                    const SizedBox(height: 24),

                    // Overall Progress
                    Text(
                      'Overall ${(clipsState.totalProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: clipsState.totalProgress,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : clipsState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${clipsState.error}',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('GO BACK'),
                      ),
                    ],
                  ),
                )
              : clipsState.clips.isEmpty
                  ? const Center(
                      child: Text(
                        'No clips available',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : Column(
                      children: [
                        // Info bar
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.white.withOpacity(0.05),
                          child: Row(
                            children: [
                              Text(
                                '${clipsState.selectedCount} of ${clipsState.clips.length} selected',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              if (clipsState.selectedCount > 0)
                                Text(
                                  'Ready to export',
                                  style: TextStyle(
                                    color: Colors.green[400],
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Clips grid
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 16 / 12,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: clipsState.clips.length,
                            itemBuilder: (context, index) {
                              final clip = clipsState.clips[index];
                              return _ClipTile(
                                clip: clip,
                                index: index,
                                onToggle: () {
                                  ref
                                      .read(clipsProvider.notifier)
                                      .toggleClip(clip.id);
                                },
                              );
                            },
                          ),
                        ),

                        // Bottom action bar
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'EXPORT ${clipsState.selectedCount} CLIPS',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Selected clips will be saved',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: clipsState.hasSelectedClips
                                    ? () {
                                        // Navigate to export with selected clips
                                        Navigator.pushNamed(
                                          context,
                                          '/export',
                                          arguments: {
                                            'clips': clipsState.selectedClips,
                                          },
                                        );
                                      }
                                    : null,
                                icon: const Icon(Icons.save_alt_rounded),
                                label: const Text('EXPORT'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  disabledBackgroundColor: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _ClipTile extends StatelessWidget {
  final dynamic clip;
  final int index;
  final VoidCallback onToggle;

  const _ClipTile({
    required this.clip,
    required this.index,
    required this.onToggle,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: clip.selected
                ? const Color(0xFF6366F1)
                : Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Thumbnail or placeholder
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                    ),
                    child: clip.thumbnailPath != null &&
                            File(clip.thumbnailPath!).existsSync()
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            child: Image.file(
                              File(clip.thumbnailPath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.videocam,
                              color: Colors.white30,
                              size: 48,
                            ),
                          ),
                  ),
                ),
                // Clip info
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clip ${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatDuration(clip.start)} - ${_formatDuration(clip.end)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Checkbox
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: clip.selected
                      ? const Color(0xFF6366F1)
                      : Colors.black.withOpacity(0.5),
                  border: Border.all(
                    color: clip.selected
                        ? const Color(0xFF6366F1)
                        : Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: clip.selected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress row widget for displaying individual stage progress
class _ProgressRow extends StatelessWidget {
  final String label;
  final double progress;

  const _ProgressRow({
    required this.label,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white12,
          valueColor: const AlwaysStoppedAnimation<Color>(
            Color(0xFF6366F1),
          ),
        ),
      ],
    );
  }
}
