import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_slider_tokens.dart';
import '_slider_theme.dart';
import 'frosted_centered_slider_track_shape.dart';

enum FrostedSliderTrack { standard, centered }

class FrostedSlider extends StatelessWidget {
  const FrostedSlider({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
    this.track = FrostedSliderTrack.standard,
    super.key,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final FrostedSliderTrack track;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return SliderTheme(
      data: frostedSliderTheme(cs).copyWith(
        thumbShape: const HandleThumbShape(),
        trackShape: switch (track) {
          FrostedSliderTrack.standard => const GappedSliderTrackShape(),
          FrostedSliderTrack.centered =>
            const FrostedCenteredSliderTrackShape(),
        },
        tickMarkShape: const RoundSliderTickMarkShape(
          tickMarkRadius: FrostedSliderTokens.tickSize / 2,
        ),
        valueIndicatorShape: const RoundedRectSliderValueIndicatorShape(),
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
