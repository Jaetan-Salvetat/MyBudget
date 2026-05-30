import 'dart:ui';

import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';

/// The filled block shared by the form inputs (text field, search, dropdown,
/// pickers).
///
/// Solid by default. When [glass] is true the fill is replaced by a blurred,
/// semi-transparent veil — letting whatever sits behind the field show
/// through. Glass on content is off-spec for Glass Expressive, so it is
/// strictly opt-in.
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
  static const double _blurSigma = 16;

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

    if (glass) {
      return ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: AnimatedContainer(
            duration: motion.duration,
            curve: motion.curve,
            padding: padding,
            decoration: BoxDecoration(
              color: _glassFill(cs),
              borderRadius: radius,
              border: border,
            ),
            child: child,
          ),
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

  Color _glassFill(ColorScheme cs) {
    if (!enabled) return cs.onSurface.withValues(alpha: 0.04);
    return cs.surfaceContainerHigh.withValues(alpha: 0.45);
  }
}
