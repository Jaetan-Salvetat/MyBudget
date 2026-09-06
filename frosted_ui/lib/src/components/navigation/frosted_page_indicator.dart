import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';

enum FrostedPageIndicatorStyle { dots, bar }

class FrostedPageIndicator extends StatelessWidget {
  const FrostedPageIndicator({
    required this.count,
    required this.currentIndex,
    this.style = FrostedPageIndicatorStyle.dots,
    super.key,
  });

  final int count;
  final int currentIndex;
  final FrostedPageIndicatorStyle style;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < count; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: motion.duration,
            curve: motion.curve,
            width: _widthFor(i),
            height: 6,
            decoration: BoxDecoration(
              color: i == currentIndex
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(FrostedRadius.full),
            ),
          ),
        ],
      ],
    );
  }

  double _widthFor(int i) {
    switch (style) {
      case FrostedPageIndicatorStyle.dots:
        return 6;
      case FrostedPageIndicatorStyle.bar:
        return i == currentIndex ? 24 : 6;
    }
  }
}
