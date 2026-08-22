import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '../navigation/frosted_menu.dart';
import '_interactive_surface.dart';

enum _SplitVariant { filled, tonal, outlined }

/// A single menu item for a [FrostedSplitButton].
class FrostedSplitMenuItem {
  const FrostedSplitMenuItem({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
}

/// A two-zone button: a primary action on the leading edge and a dropdown
/// chevron on the trailing edge that surfaces a menu of related actions.
///
/// The two zones are separate segments split by a small gap. Outer corners
/// are fully rounded; the inner corners (facing the gap) are softer. The
/// chevron morphs to a circle while its menu is open, per M3 Expressive.
class FrostedSplitButton extends StatelessWidget {
  const FrostedSplitButton._({
    super.key,
    required this.label,
    required _SplitVariant variant,
    required this.menuItems,
    this.icon,
    this.onPressed,
  }) : _variant = variant;

  factory FrostedSplitButton.filled({
    Key? key,
    required String label,
    IconData? icon,
    required VoidCallback? onPressed,
    required List<FrostedSplitMenuItem> menuItems,
  }) => FrostedSplitButton._(
    key: key,
    label: label,
    variant: _SplitVariant.filled,
    menuItems: menuItems,
    icon: icon,
    onPressed: onPressed,
  );

  factory FrostedSplitButton.tonal({
    Key? key,
    required String label,
    IconData? icon,
    required VoidCallback? onPressed,
    required List<FrostedSplitMenuItem> menuItems,
  }) => FrostedSplitButton._(
    key: key,
    label: label,
    variant: _SplitVariant.tonal,
    menuItems: menuItems,
    icon: icon,
    onPressed: onPressed,
  );

  factory FrostedSplitButton.outlined({
    Key? key,
    required String label,
    IconData? icon,
    required VoidCallback? onPressed,
    required List<FrostedSplitMenuItem> menuItems,
  }) => FrostedSplitButton._(
    key: key,
    label: label,
    variant: _SplitVariant.outlined,
    menuItems: menuItems,
    icon: icon,
    onPressed: onPressed,
  );

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final List<FrostedSplitMenuItem> menuItems;
  final _SplitVariant _variant;

  static const double _height = 48;
  static const double _pill = _height / 2;
  static const double _inner = FrostedRadius.md;
  static const double _innerPressed = FrostedRadius.xs;
  static const double _gap = FrostedSpacing.sp05;

  @override
  Widget build(BuildContext context) {
    final FrostedMotion motion = context.frostedTokens.motion.snappy;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _MainAction(
          label: label,
          icon: icon,
          variant: _variant,
          onPressed: onPressed,
          motion: motion,
        ),
        const SizedBox(width: _gap),
        _ChevronAction(
          variant: _variant,
          enabled: menuItems.isNotEmpty,
          items: menuItems,
          motion: motion,
        ),
      ],
    );
  }
}

BoxDecoration _decoration({
  required ColorScheme cs,
  required InteractionStates s,
  required _SplitVariant variant,
  required BorderRadius borderRadius,
}) {
  return BoxDecoration(
    color: _resolveBg(cs, s, variant),
    borderRadius: borderRadius,
    border: variant == _SplitVariant.outlined
        ? Border.all(
            color: s.enabled
                ? cs.outline
                : cs.onSurface.withValues(alpha: 0.12),
          )
        : null,
  );
}

class _MainAction extends StatelessWidget {
  const _MainAction({
    required this.label,
    required this.icon,
    required this.variant,
    required this.onPressed,
    required this.motion,
  });

  final String label;
  final IconData? icon;
  final _SplitVariant variant;
  final VoidCallback? onPressed;
  final FrostedMotion motion;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return InteractiveSurface(
      onTap: onPressed,
      semanticsLabel: label,
      builder: (BuildContext context, InteractionStates s) {
        final Color fg = _resolveFg(cs, s, variant);
        final BorderRadius radius = _shape(s);

        return AnimatedContainer(
          duration: motion.duration,
          curve: motion.curve,
          height: FrostedSplitButton._height,
          alignment: Alignment.center,
          decoration: _decoration(
            cs: cs,
            s: s,
            variant: variant,
            borderRadius: radius,
          ),
          child: s.ink(
            color: fg,
            borderRadius: radius,
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FrostedSpacing.sp5,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: FrostedSpacing.sp2),
                  ],
                  Text(
                    label,
                    style: FrostedTypeScale.labelLarge.copyWith(color: fg),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  BorderRadius _shape(InteractionStates s) => BorderRadius.horizontal(
    left: const Radius.circular(FrostedSplitButton._pill),
    right: Radius.circular(
      s.pressed ? FrostedSplitButton._innerPressed : FrostedSplitButton._inner,
    ),
  );
}

class _ChevronAction extends StatelessWidget {
  const _ChevronAction({
    required this.variant,
    required this.enabled,
    required this.items,
    required this.motion,
  });

  final _SplitVariant variant;
  final bool enabled;
  final List<FrostedSplitMenuItem> items;
  final FrostedMotion motion;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(Colors.transparent),
        elevation: WidgetStatePropertyAll<double>(0),
        padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.zero),
        shadowColor: WidgetStatePropertyAll<Color>(Colors.transparent),
        surfaceTintColor: WidgetStatePropertyAll<Color>(Colors.transparent),
      ),
      menuChildren: <Widget>[_SplitMenu(items: items)],
      builder: (BuildContext context, MenuController controller, Widget? _) {
        final bool open = controller.isOpen;
        return InteractiveSurface(
          onTap: enabled
              ? () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                }
              : null,
          builder: (BuildContext context, InteractionStates s) {
            final Color fg = _resolveFg(cs, s, variant);
            final BorderRadius radius = open
                ? BorderRadius.circular(FrostedSplitButton._pill)
                : BorderRadius.horizontal(
                    left: Radius.circular(
                      s.pressed
                          ? FrostedSplitButton._innerPressed
                          : FrostedSplitButton._inner,
                    ),
                    right: const Radius.circular(FrostedSplitButton._pill),
                  );

            return AnimatedContainer(
              duration: motion.duration,
              curve: motion.curve,
              height: FrostedSplitButton._height,
              width: FrostedSplitButton._height,
              alignment: Alignment.center,
              decoration: _decoration(
                cs: cs,
                s: s,
                variant: variant,
                borderRadius: radius,
              ),
              child: s.ink(
                color: fg,
                borderRadius: radius,
                AnimatedRotation(
                  duration: motion.duration,
                  curve: motion.curve,
                  turns: open ? 0.5 : 0,
                  child: Icon(Icons.keyboard_arrow_down, size: 22, color: fg),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SplitMenu extends StatelessWidget {
  const _SplitMenu({required this.items});

  final List<FrostedSplitMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final MenuController? controller = MenuController.maybeOf(context);
    return FrostedMenuPanel(
      entries: <FrostedMenuEntry>[
        for (final FrostedSplitMenuItem item in items)
          FrostedMenuEntry(
            label: item.label,
            icon: item.icon,
            onTap: () {
              item.onTap();
              controller?.close();
            },
          ),
      ],
    );
  }
}

Color _resolveBg(ColorScheme cs, InteractionStates s, _SplitVariant variant) {
  if (!s.enabled) {
    if (variant == _SplitVariant.filled || variant == _SplitVariant.tonal) {
      return cs.onSurface.withValues(alpha: 0.12);
    }
    return Colors.transparent;
  }
  Color base;
  Color overlay;
  switch (variant) {
    case _SplitVariant.filled:
      base = cs.primary;
      overlay = cs.onPrimary;
      break;
    case _SplitVariant.tonal:
      base = cs.secondaryContainer;
      overlay = cs.onSecondaryContainer;
      break;
    case _SplitVariant.outlined:
      base = Colors.transparent;
      overlay = cs.primary;
      break;
  }
  double alpha = 0;
  if (s.pressed) {
    alpha = 0.12;
  } else if (s.focused) {
    alpha = 0.10;
  } else if (s.hovered) {
    alpha = 0.08;
  }
  if (alpha == 0) return base;
  return Color.alphaBlend(overlay.withValues(alpha: alpha), base);
}

Color _resolveFg(ColorScheme cs, InteractionStates s, _SplitVariant variant) {
  if (!s.enabled) return cs.onSurface.withValues(alpha: 0.38);
  switch (variant) {
    case _SplitVariant.filled:
      return cs.onPrimary;
    case _SplitVariant.tonal:
      return cs.onSecondaryContainer;
    case _SplitVariant.outlined:
      return cs.primary;
  }
}
