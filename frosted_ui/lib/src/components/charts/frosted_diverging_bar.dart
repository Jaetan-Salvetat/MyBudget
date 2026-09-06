import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_chart_tokens.dart';

enum FrostedDivergingSide { leading, trailing }

class FrostedDivergingBar extends StatelessWidget {
  const FrostedDivergingBar({
    required this.factor,
    required this.side,
    required this.color,
    this.axisColor,
    this.thickness = FrostedChartTokens.barThickness,
    this.radius = FrostedChartTokens.divergingRadius,
    super.key,
  });

  final double factor;
  final FrostedDivergingSide side;
  final Color color;
  final Color? axisColor;
  final double thickness;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool trailing = side == FrostedDivergingSide.trailing;
    final Widget bar = FractionallySizedBox(
      widthFactor: factor.clamp(0.0, 1.0),
      child: Container(
        height: thickness,
        decoration: BoxDecoration(
          color: color,
          borderRadius: trailing
              ? BorderRadius.horizontal(right: Radius.circular(radius))
              : BorderRadius.horizontal(left: Radius.circular(radius)),
        ),
      ),
    );

    return SizedBox(
      height: thickness + FrostedChartTokens.divergingVerticalPadding,
      child: Row(
        children: <Widget>[
          Expanded(
            child: trailing
                ? const SizedBox.shrink()
                : Align(alignment: Alignment.centerRight, child: bar),
          ),
          Container(
            width: FrostedChartTokens.divergingAxisThickness,
            color: axisColor ?? cs.outlineVariant,
          ),
          Expanded(
            child: trailing
                ? Align(alignment: Alignment.centerLeft, child: bar)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
