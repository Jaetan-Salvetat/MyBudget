import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/frosted_glass_tokens.dart';
import '../../theme/frosted_tokens.dart';

/// The layer painted behind a modal overlay: it blurs the page underneath and
/// lays a translucent veil over it, so glass chrome above reads against a
/// softened, dimmed backdrop (the iOS/M3 modal feel).
///
/// Both blur and veil ramp in with the route transition [animation]; tapping
/// dismisses the barrier when [onDismiss] is provided.
class FrostedScrim extends StatelessWidget {
  const FrostedScrim({
    required this.animation,
    this.onDismiss,
    this.blurSigma = 6,
    super.key,
  });

  final Animation<double> animation;
  final VoidCallback? onDismiss;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final FrostedGlassTokens glass = context.frostedTokens.glass;
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double t = animation.value.clamp(0, 1);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma * t,
            sigmaY: blurSigma * t,
          ),
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: ColoredBox(
              color: glass.scrim.withValues(alpha: glass.scrim.a * t),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}
