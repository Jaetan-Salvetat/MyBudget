import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../primitives/frosted_glass.dart';
import '../../primitives/frosted_glass_level.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';

class FrostedFieldSurface extends StatelessWidget {
  const FrostedFieldSurface({
    required this.child,
    required this.focused,
    required this.hasError,
    required this.enabled,
    this.glass = false,
    this.padding,
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final bool focused;
  final bool hasError;
  final bool enabled;
  final bool glass;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  static const double _ringWidth = 2;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;
    final BorderRadius radius =
        borderRadius ?? BorderRadius.circular(FrostedRadius.md);
    final Color ring = hasError ? cs.error : cs.primary;
    final Border border = Border.all(
      color: focused || hasError ? ring : Colors.transparent,
      width: _ringWidth,
    );

    if (glass && enabled) {
      return AnimatedContainer(
        duration: motion.duration,
        curve: motion.curve,
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: border,
        ),
        child: FrostedGlass(
          level: FrostedGlassLevel.ultraThick,
          tone: FrostedGlassTone.auto,
          elevation: FrostedGlassElevation.none,
          borderRadius: radius,
          padding: padding,
          child: child,
        ),
      );
    }

    return AnimatedContainer(
      duration: motion.duration,
      curve: motion.curve,
      padding: padding,
      decoration: BoxDecoration(
        color: _solidFill(cs),
        borderRadius: radius,
        border: border,
      ),
      child: child,
    );
  }

  Color _solidFill(ColorScheme cs) {
    if (!enabled) return cs.onSurface.withValues(alpha: 0.04);
    return cs.surfaceContainerHigh;
  }
}
