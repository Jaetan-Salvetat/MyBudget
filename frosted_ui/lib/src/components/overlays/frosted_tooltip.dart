import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';

/// A small label shown on hover (pointer) or long-press (touch).
///
/// Wraps Flutter's [Tooltip] for timing, positioning and dismissal, restyled
/// as a near-neutral inverse-surface chip.
class FrostedTooltip extends StatelessWidget {
  const FrostedTooltip({required this.message, required this.child, super.key});

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: message,
      textStyle: FrostedTypeScale.labelMedium.copyWith(
        color: cs.onInverseSurface,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: FrostedSpacing.sp3,
        vertical: FrostedSpacing.sp2,
      ),
      decoration: BoxDecoration(
        color: cs.inverseSurface,
        borderRadius: BorderRadius.circular(FrostedRadius.sm),
      ),
      child: child,
    );
  }
}
