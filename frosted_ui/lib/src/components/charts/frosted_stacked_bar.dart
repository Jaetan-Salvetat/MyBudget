import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_chart_tokens.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '_stacked_bar_fractions.dart';
import 'frosted_bar_segment.dart';

class FrostedStackedBar extends StatelessWidget {
  const FrostedStackedBar({
    required this.segments,
    this.thickness = FrostedChartTokens.barThickness,
    this.gap = FrostedChartTokens.barGap,
    this.radius = FrostedChartTokens.barRadius,
    this.animated = false,
    super.key,
  });

  final List<FrostedBarSegment> segments;
  final double thickness;
  final double gap;
  final double radius;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final StackedBarFractions fractions = StackedBarFractions.of(segments);
    if (fractions.isEmpty) return SizedBox(height: thickness);

    return SizedBox(
      height: thickness,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (!animated) return _bars(fractions, constraints.maxWidth);

          final FrostedMotion motion = context.frostedTokens.motion.fluid;
          return TweenAnimationBuilder<StackedBarFractions>(
            tween: StackedBarFractionsTween(end: fractions),
            duration: motion.duration,
            curve: motion.curve,
            builder:
                (
                  BuildContext context,
                  StackedBarFractions value,
                  Widget? child,
                ) => _bars(value, constraints.maxWidth),
          );
        },
      ),
    );
  }

  Widget _bars(StackedBarFractions fractions, double maxWidth) {
    final double free = maxWidth - gap * (fractions.length - 1);

    return Row(
      children: <Widget>[
        for (int index = 0; index < fractions.length; index++) ...<Widget>[
          if (index > 0) SizedBox(width: gap),
          Container(
            width: free * fractions[index].fraction,
            decoration: BoxDecoration(
              color: fractions[index].color,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        ],
      ],
    );
  }
}
