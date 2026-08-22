import 'package:flutter/material.dart';

import '../../foundations/frosted_type_scale.dart';

/// A thin two-handle range slider, matching [FrostedSlider]'s scrubber look.
///
/// Opaque M3 content surface. Pass [divisions] to make it discrete; value
/// labels appear above each handle while dragging.
class FrostedRangeSlider extends StatelessWidget {
  const FrostedRangeSlider({
    required this.values,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.labels,
    super.key,
  });

  final RangeValues values;
  final ValueChanged<RangeValues>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final RangeLabels? labels;

  static const double _trackHeight = 4;
  static const double _knobRadius = 6;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return SliderTheme(
      data: SliderThemeData(
        trackHeight: _trackHeight,
        activeTrackColor: cs.primary,
        inactiveTrackColor: cs.surfaceContainerHighest,
        thumbColor: cs.primary,
        rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: _knobRadius,
        ),
        overlayColor: cs.primary.withValues(alpha: 0.12),
        valueIndicatorColor: cs.inverseSurface,
        valueIndicatorTextStyle: FrostedTypeScale.labelMedium.copyWith(
          color: cs.onInverseSurface,
        ),
        rangeValueIndicatorShape: const PaddleRangeSliderValueIndicatorShape(),
        showValueIndicator: ShowValueIndicator.onlyForDiscrete,
      ),
      child: RangeSlider(
        values: values,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        labels: labels,
      ),
    );
  }
}
