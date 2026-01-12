import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/duration_utils.dart';

/// Trim slider widget for adjusting clip start and end times
class TrimSlider extends StatefulWidget {
  final Duration clipDuration;
  final Duration trimStart;
  final Duration trimEnd;
  final ValueChanged<Duration> onTrimStartChanged;
  final ValueChanged<Duration> onTrimEndChanged;

  const TrimSlider({
    super.key,
    required this.clipDuration,
    required this.trimStart,
    required this.trimEnd,
    required this.onTrimStartChanged,
    required this.onTrimEndChanged,
  });

  @override
  State<TrimSlider> createState() => _TrimSliderState();
}

class _TrimSliderState extends State<TrimSlider> {
  late RangeValues _rangeValues;

  @override
  void initState() {
    super.initState();
    _updateRangeValues();
  }

  @override
  void didUpdateWidget(TrimSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trimStart != widget.trimStart ||
        oldWidget.trimEnd != widget.trimEnd) {
      _updateRangeValues();
    }
  }

  void _updateRangeValues() {
    final totalMs = widget.clipDuration.inMilliseconds.toDouble();
    if (totalMs <= 0) {
      _rangeValues = const RangeValues(0, 1);
      return;
    }

    final startNormalized = widget.trimStart.inMilliseconds / totalMs;
    final endNormalized = (totalMs + widget.trimEnd.inMilliseconds) / totalMs;

    _rangeValues = RangeValues(
      startNormalized.clamp(0.0, 1.0),
      endNormalized.clamp(0.0, 1.0),
    );
  }

  void _onRangeChanged(RangeValues values) {
    setState(() => _rangeValues = values);

    final totalMs = widget.clipDuration.inMilliseconds;
    final newStart = Duration(milliseconds: (values.start * totalMs).round());
    final newEnd = Duration(
        milliseconds:
            ((values.end - 1.0) * totalMs).round()); // Negative offset

    widget.onTrimStartChanged(newStart);
    widget.onTrimEndChanged(newEnd);
  }

  Duration get effectiveDuration {
    final totalMs = widget.clipDuration.inMilliseconds;
    final startMs = (widget.trimStart.inMilliseconds).abs();
    final endMs = (widget.trimEnd.inMilliseconds).abs();
    return Duration(
        milliseconds: (totalMs - startMs - endMs).clamp(0, totalMs));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TRIM',
              style: AppTypography.labelLarge,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingS,
                vertical: AppConstants.paddingXS,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Text(
                DurationUtils.formatMinutesSeconds(effectiveDuration),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.paddingM),

        // Range slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.surfaceLight,
            thumbColor: AppColors.accent,
            overlayColor: AppColors.accent.withOpacity(0.2),
          ),
          child: RangeSlider(
            values: _rangeValues,
            min: 0.0,
            max: 1.0,
            divisions: 100,
            onChanged: _onRangeChanged,
          ),
        ),

        // Time labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DurationUtils.formatMinutesSeconds(widget.trimStart),
                style: AppTypography.caption,
              ),
              Text(
                DurationUtils.formatMinutesSeconds(
                  widget.clipDuration + widget.trimEnd,
                ),
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
