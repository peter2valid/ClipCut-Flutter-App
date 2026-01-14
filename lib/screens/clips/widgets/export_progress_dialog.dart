import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/export_progress.dart' as models;
import '../../../providers/clip_provider.dart';
import '../../../core/utils/file_utils.dart';

/// Example: Export progress dialog (P1)
/// Shows batch export with per-clip and overall progress
class ExportProgressDialog extends ConsumerStatefulWidget {
  const ExportProgressDialog({super.key});

  @override
  ConsumerState<ExportProgressDialog> createState() =>
      _ExportProgressDialogState();
}

class _ExportProgressDialogState extends ConsumerState<ExportProgressDialog> {
  bool _isExporting = false;
  models.ExportProgress? _lastProgress;

  Future<void> _startExport() async {
    setState(() => _isExporting = true);

    try {
      final exportDir = await FileUtils.getExportDirectory();

      await ref.read(clipsProvider.notifier).exportSelectedClips(
            outputDir: exportDir.path,
            onProgress: (progress) {
              setState(() => _lastProgress = progress);
            },
          );

      // Success!
      if (mounted && (_lastProgress?.isComplete ?? false)) {
        Navigator.of(context).pop(_lastProgress?.completedPaths);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _cancelExport() {
    ref.read(clipsProvider.notifier).cancelExport();
  }

  @override
  void initState() {
    super.initState();
    // Auto-start export when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startExport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _lastProgress;

    return WillPopScope(
      onWillPop: () async {
        if (_isExporting) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cancel Export?'),
              content: const Text('Export is in progress. Cancel?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CONTINUE'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('CANCEL'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            _cancelExport();
          }
          return confirm ?? false;
        }
        return true;
      },
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              const Text(
                'EXPORTING CLIPS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Overall progress
              if (progress != null) ...[
                LinearProgressIndicator(
                  value: progress.batchProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                ),
                const SizedBox(height: 8),
                Text(
                  '${progress.currentClipIndex + 1} / ${progress.totalClips} clips',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  progress.percentageString,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 16),

                // Current clip progress
                if (progress.currentClipPath != null) ...[
                  Text(
                    'Current: ${progress.currentClipPath}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.currentClipProgress,
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(height: 16),
                ],

                // Statistics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      icon: Icons.check_circle,
                      label: 'Completed',
                      value: '${progress.completedPaths.length}',
                      color: Colors.green,
                    ),
                    if (progress.failedClips.isNotEmpty)
                      _StatItem(
                        icon: Icons.error,
                        label: 'Failed',
                        value: '${progress.failedClips.length}',
                        color: Colors.red,
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Cancel button
              if (_isExporting && progress != null && !progress.isCancelled)
                OutlinedButton(
                  onPressed: _cancelExport,
                  child: const Text('CANCEL EXPORT'),
                ),

              // Close button (when done)
              if (!_isExporting || (progress?.isCancelled ?? false))
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    progress?.isCancelled == true ? 'CLOSE' : 'DONE',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

/// Usage Example in SimpleClipsScreen:
/// 
/// ElevatedButton(
///   onPressed: () async {
///     final result = await showDialog<List<String>>(
///       context: context,
///       barrierDismissible: false,
///       builder: (context) => const ExportProgressDialog(),
///     );
///     
///     if (result != null && result.isNotEmpty) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text('Exported ${result.length} clips!')),
///       );
///     }
///   },
///   child: const Text('EXPORT'),
/// )
