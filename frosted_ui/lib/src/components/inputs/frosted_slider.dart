import 'package:flutter/material.dart';

import '../../foundations/frosted_type_scale.dart';

/// A thin single-value slider, modelled on the mockup's player scrubber.
///
/// Opaque M3 content surface: a 4dp track with a primary fill and a small
/// round knob. Pass [divisions] to make it discrete; the value label appears
/// above the knob while dragging.
class FrostedSlider extends StatelessWidget {
  const FrostedSlider({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
    super.key,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;

  // Mockup `.scrub-track` height 4 / radius 4; `.scrub-knob` 12×12 round.
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
        overlayColor: cs.primary.withValues(alpha: 0.12),
        valueIndicatorColor: cs.inverseSurface,
        valueIndicatorTextStyle: FrostedTypeScale.labelMedium
            .copyWith(color: cs.onInverseSurface),
        trackShape: const RoundedRectSliderTrackShape(),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: _knobRadius),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        showValueIndicator: ShowValueIndicator.onlyForDiscrete,
      ),
      child: Slider(
        value: value.clamp(min, max),
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        label: label,
      ),
    );
  }
}
