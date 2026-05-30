import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../actions/_interactive_surface.dart';

/// An inline informational bar on `secondaryContainer`: an optional icon, a
/// message, and an optional call-to-action pill.
///
/// Opaque M3 content surface. Use it for contextual notices inside a screen,
/// not for transient feedback (that's a snackbar).
class FrostedBanner extends StatelessWidget {
  const FrostedBanner({
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FrostedSpacing.sp4,
        vertical: FrostedSpacing.sp3 + 2,
      ),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(FrostedRadius.lg),
      ),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 22, color: cs.onSecondaryContainer),
            const SizedBox(width: FrostedSpacing.sp3 + 2),
          ],
          Expanded(
            child: Text(
              message,
              style: FrostedTypeScale.bodyMedium
                  .copyWith(color: cs.onSecondaryContainer),
            ),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(width: FrostedSpacing.sp3),
            _BannerCta(label: actionLabel!, onTap: onAction!),
          ],
        ],
      ),
    );
  }
}

class _BannerCta extends StatelessWidget {
  const _BannerCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return InteractiveSurface(
      onTap: onTap,
      semanticsLabel: label,
      shape: (_) => BorderRadius.circular(FrostedRadius.full),
      builder: (BuildContext context, InteractionStates s) {
        final double overlay = s.pressed
            ? 0.12
            : s.focused
                ? 0.10
                : s.hovered
                    ? 0.08
                    : 0;
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: FrostedSpacing.sp4,
            vertical: FrostedSpacing.sp2 + 2,
          ),
          decoration: BoxDecoration(
            color: overlay == 0
                ? cs.primary
                : Color.alphaBlend(
                    cs.onPrimary.withValues(alpha: overlay), cs.primary),
            borderRadius: BorderRadius.circular(FrostedRadius.full),
          ),
          child: Text(
            label,
            style: FrostedTypeScale.labelLarge.copyWith(color: cs.onPrimary),
          ),
        );
      },
    );
  }
}
