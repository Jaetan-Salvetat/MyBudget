import 'package:flutter/material.dart';

import '../../foundations/frosted_shape.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '_interactive_surface.dart';

enum _ButtonVariant { filled, tonal, outlined, text }

/// A standard text button.
///
/// Comes in four flavours via named constructors: [filled], [tonal],
/// [outlined], [text]. Pass `onPressed: null` to disable.
///
/// [shape] picks the resting form — [FrostedShape.rounded] by default, or
/// [FrostedShape.pill] for the fully rounded form. A press morphs it into the
/// other one and back, so the two shapes are each other's press state.
class FrostedButton extends StatelessWidget {
  const FrostedButton._({
    super.key,
    required this.label,
    required _ButtonVariant variant,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.expanded = false,
    this.shape = FrostedShape.rounded,
    this.destructive = false,
  }) : _variant = variant;

  /// Solid filled button — primary action on a page.
  factory FrostedButton.filled({
    Key? key,
    required String label,
    IconData? icon,
    IconData? trailingIcon,
    required VoidCallback? onPressed,
    bool expanded = false,
    FrostedShape shape = FrostedShape.rounded,
    bool destructive = false,
  }) => FrostedButton._(
    key: key,
    label: label,
    variant: _ButtonVariant.filled,
    icon: icon,
    trailingIcon: trailingIcon,
    onPressed: onPressed,
    expanded: expanded,
    shape: shape,
    destructive: destructive,
  );

  /// Tonal button — secondary action, sits next to a filled one.
  factory FrostedButton.tonal({
    Key? key,
    required String label,
    IconData? icon,
    IconData? trailingIcon,
    required VoidCallback? onPressed,
    bool expanded = false,
    FrostedShape shape = FrostedShape.rounded,
    bool destructive = false,
  }) => FrostedButton._(
    key: key,
    label: label,
    variant: _ButtonVariant.tonal,
    icon: icon,
    trailingIcon: trailingIcon,
    onPressed: onPressed,
    expanded: expanded,
    shape: shape,
    destructive: destructive,
  );

  /// Outlined button — alternative action, low emphasis.
  factory FrostedButton.outlined({
    Key? key,
    required String label,
    IconData? icon,
    IconData? trailingIcon,
    required VoidCallback? onPressed,
    bool expanded = false,
    FrostedShape shape = FrostedShape.rounded,
    bool destructive = false,
  }) => FrostedButton._(
    key: key,
    label: label,
    variant: _ButtonVariant.outlined,
    icon: icon,
    trailingIcon: trailingIcon,
    onPressed: onPressed,
    expanded: expanded,
    shape: shape,
    destructive: destructive,
  );

  /// Text button — least emphasis. No background or border.
  factory FrostedButton.text({
    Key? key,
    required String label,
    IconData? icon,
    IconData? trailingIcon,
    required VoidCallback? onPressed,
    bool expanded = false,
    FrostedShape shape = FrostedShape.rounded,
    bool destructive = false,
  }) => FrostedButton._(
    key: key,
    label: label,
    variant: _ButtonVariant.text,
    icon: icon,
    trailingIcon: trailingIcon,
    onPressed: onPressed,
    expanded: expanded,
    shape: shape,
    destructive: destructive,
  );

  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final bool expanded;

  /// Swaps the primary role for the error role, marking the action as
  /// irreversible. Disabled buttons stay neutral.
  final bool destructive;

  /// The resting form. A press morphs it into [FrostedShape.opposite].
  final FrostedShape shape;

  final _ButtonVariant _variant;

  /// Buttons carry a fixed height so the pill radius is exactly half of it,
  /// which keeps the morph to [FrostedShape.rounded] a linear interpolation.
  static const double _height = 46;
  static const Size _box = Size(double.infinity, _height);

  /// Easing for a surface that appears from nothing rather than shifting one
  /// already on screen. Symmetric, so the first frames carry visible travel.
  static const Curve _arrivalCurve = Curves.easeInOutCubic;

  /// Pressed state-layer weight. On a text button the layer is the whole
  /// visible surface instead of a modulation of an opaque one, so it takes
  /// more alpha to read at all.
  static const double _pressedOverlayAlpha = 0.12;
  static const double _pressedBareOverlayAlpha = 0.16;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotionTokens motionTokens = context.frostedTokens.motion;
    final bool isText = _variant == _ButtonVariant.text;

    // Every other variant already carries a surface at rest, so a press only
    // shifts one that is on screen and the near-instant snappy settle reads
    // fine. A text button has nothing at rest: its state layer has to arrive
    // from transparent, and the spring-settle tokens are front-loaded enough
    // to turn that arrival into a pop rather than a fade.
    final FrostedMotion motion = isText
        ? FrostedMotion(
            duration: motionTokens.snappy.duration,
            curve: _arrivalCurve,
          )
        : motionTokens.snappy;

    return InteractiveSurface(
      onTap: onPressed,
      semanticsLabel: label,
      builder: (BuildContext context, InteractionStates s) {
        final Color bg = _resolveBg(cs, s);
        final Color fg = _resolveFg(cs, s);
        final BorderSide? border = _resolveBorder(cs, s);

        // The padding sits inside the ripple rather than on the container, so
        // the ink spreads over the whole surface instead of only the box the
        // label occupies. Clipping is the container's job for the same reason:
        // it follows the radius as the shape morphs.
        final Widget core = AnimatedContainer(
          duration: motion.duration,
          curve: motion.curve,
          height: _height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: _shape(s),
            border: border != null ? Border.fromBorderSide(border) : null,
          ),
          child: s.ink(
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isText
                    ? FrostedSpacing.sp3 + 2
                    : FrostedSpacing.sp5,
              ),
              child: Row(
                mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: FrostedSpacing.sp2),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: FrostedTypeScale.labelLarge.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailingIcon != null) ...<Widget>[
                    const SizedBox(width: FrostedSpacing.sp2),
                    Icon(trailingIcon, size: 18, color: fg),
                  ],
                ],
              ),
            ),
          ),
        );

        if (expanded) {
          return SizedBox(width: double.infinity, child: core);
        }
        return core;
      },
    );
  }

  BorderRadius _shape(InteractionStates s) =>
      shape.resolve(_box, pressed: s.pressed);

  Color _resolveBg(ColorScheme cs, InteractionStates s) {
    if (!s.enabled) {
      if (_variant == _ButtonVariant.filled ||
          _variant == _ButtonVariant.tonal) {
        return cs.onSurface.withValues(alpha: 0.12);
      }
      return Colors.transparent;
    }
    final Color base = switch (_variant) {
      _ButtonVariant.filled => destructive ? cs.error : cs.primary,
      _ButtonVariant.tonal =>
        destructive ? cs.errorContainer : cs.secondaryContainer,
      _ButtonVariant.outlined => Colors.transparent,
      _ButtonVariant.text => Colors.transparent,
    };
    final Color overlayBase = _resolveFg(cs, s);
    final double alpha = _overlayAlpha(s);
    if (alpha == 0) return base;
    return Color.alphaBlend(overlayBase.withValues(alpha: alpha), base);
  }

  Color _resolveFg(ColorScheme cs, InteractionStates s) {
    if (!s.enabled) {
      return cs.onSurface.withValues(alpha: 0.38);
    }
    return switch (_variant) {
      _ButtonVariant.filled => destructive ? cs.onError : cs.onPrimary,
      _ButtonVariant.tonal =>
        destructive ? cs.onErrorContainer : cs.onSecondaryContainer,
      _ButtonVariant.outlined => destructive ? cs.error : cs.primary,
      _ButtonVariant.text => destructive ? cs.error : cs.primary,
    };
  }

  BorderSide? _resolveBorder(ColorScheme cs, InteractionStates s) {
    if (_variant != _ButtonVariant.outlined) return null;
    if (!s.enabled) {
      return BorderSide(color: cs.onSurface.withValues(alpha: 0.12));
    }
    if (destructive) return BorderSide(color: cs.error);
    final Color color = s.focused ? cs.primary : cs.outline;
    return BorderSide(color: color);
  }

  double _overlayAlpha(InteractionStates s) {
    if (s.pressed) {
      return _variant == _ButtonVariant.text
          ? _pressedBareOverlayAlpha
          : _pressedOverlayAlpha;
    }
    if (s.focused) return 0.10;
    if (s.hovered) return 0.08;
    return 0;
  }
}
