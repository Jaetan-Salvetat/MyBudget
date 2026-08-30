import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '../actions/_interactive_surface.dart';

enum FrostedCardVariant {
  filled,

  outlined,

  accent,
}

class FrostedCard extends StatelessWidget {
  const FrostedCard({
    required this.child,
    this.variant = FrostedCardVariant.filled,
    this.padding = const EdgeInsets.all(FrostedSpacing.sp4 + 2),
    this.onTap,
    this.radius = FrostedRadius.lg,
    super.key,
  });

  final Widget child;
  final FrostedCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  final double radius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    if (onTap == null) {
      return DecoratedBox(
        decoration: _decoration(cs, pressed: false),
        child: Padding(padding: padding, child: child),
      );
    }

    final FrostedMotion motion = context.frostedTokens.motion.snappy;
    return InteractiveSurface(
      onTap: onTap,
      builder: (BuildContext context, InteractionStates s) {
        return AnimatedContainer(
          duration: motion.duration,
          curve: motion.curve,
          clipBehavior: Clip.antiAlias,
          decoration: _decoration(cs, pressed: s.pressed),
          child: s.ink(Padding(padding: padding, child: child)),
        );
      },
    );
  }

  double _radiusFor({required bool pressed}) =>
      pressed ? FrostedRadius.stepDown(radius) : radius;

  BoxDecoration _decoration(ColorScheme cs, {required bool pressed}) {
    final double radius = _radiusFor(pressed: pressed);
    switch (variant) {
      case FrostedCardVariant.filled:
        return BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(radius),
        );
      case FrostedCardVariant.outlined:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: cs.outlineVariant),
        );
      case FrostedCardVariant.accent:
        return BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(radius),
        );
    }
  }
}
