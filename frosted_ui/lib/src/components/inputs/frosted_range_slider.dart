import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_slider_tokens.dart';
import '_slider_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return SliderTheme(
      data: frostedSliderTheme(cs).copyWith(
        rangeThumbShape: const HandleRangeSliderThumbShape(),
        rangeTrackShape: const GappedRangeSliderTrackShape(),
        rangeTickMarkShape: const RoundRangeSliderTickMarkShape(
          tickMarkRadius: FrostedSliderTokens.tickSize / 2,
        ),
        rangeValueIndicatorShape:
            const RoundedRectRangeSliderValueIndicatorShape(),
        minThumbSeparation: 0,
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
