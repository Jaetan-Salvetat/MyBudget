import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_chart_tokens.dart';

class FrostedChartDot extends StatelessWidget {
  const FrostedChartDot({
    required this.color,
    this.size = FrostedChartTokens.dotSize,
    this.radius,
    super.key,
  });

  final Color color;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final double? radius = this.radius;

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: radius == null ? null : BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
