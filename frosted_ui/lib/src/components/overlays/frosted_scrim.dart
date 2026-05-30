import 'package:flutter/material.dart';

import '../../theme/frosted_glass_tokens.dart';
import '../../theme/frosted_tokens.dart';

/// The dimming layer painted behind a modal overlay.
///
/// Fades in with the route transition [animation] and dismisses the barrier
/// on tap when [onDismiss] is provided.
class FrostedScrim extends StatelessWidget {
  const FrostedScrim({
    required this.animation,
    this.onDismiss,
    super.key,
  });

  final Animation<double> animation;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final FrostedGlassTokens glass = context.frostedTokens.glass;
    return FadeTransition(
      opacity: animation,
      child: GestureDetector(
        onTap: onDismiss,
        behavior: HitTestBehavior.opaque,
        child: ColoredBox(color: glass.scrim, child: const SizedBox.expand()),
      ),
    );
  }
}
