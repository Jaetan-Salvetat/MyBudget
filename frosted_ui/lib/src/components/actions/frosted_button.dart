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
  }) =>
      FrostedButton._(
        key: key,
        label: label,
        variant: _ButtonVariant.filled,
        icon: icon,
        trailingIcon: trailingIcon,
        onPressed: onPressed,
        expanded: expanded,
        shape: shape,
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
  }) =>
      FrostedButton._(
        key: key,
        label: label,
        variant: _ButtonVariant.tonal,
        icon: icon,
        trailingIcon: trailingIcon,
        onPressed: onPressed,
        expanded: expanded,
        shape: shape,
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
  }) =>
      FrostedButton._(
        key: key,
        label: label,
        variant: _ButtonVariant.outlined,
        icon: icon,
        trailingIcon: trailingIcon,
        onPressed: onPressed,
        expanded: expanded,
        shape: shape,
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
  }) =>
      FrostedButton._(
        key: key,
        label: label,
        variant: _ButtonVariant.text,
        icon: icon,
        trailingIcon: trailingIcon,
        onPressed: onPressed,
        expanded: expanded,
        shape: shape,
      );

  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final bool expanded;

  /// The resting form. A press morphs it into [FrostedShape.opposite].
  final FrostedShape shape;

  final _ButtonVariant _variant;

  /// Buttons carry a fixed height so the pill radius is exactly half of it,
  /// which keeps the morph to [FrostedShape.rounded] a linear interpolation.
  static const double _height = 46;
  static const Size _box = Size(double.infinity, _height);

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;
    final bool isText = _variant == _ButtonVariant.text;

    return InteractiveSurface(
      onTap: onPressed,
      semanticsLabel: label,
      shape: _shape,
      builder: (BuildContext context, InteractionStates s) {
        final Color bg = _resolveBg(cs, s);
        final Color fg = _resolveFg(cs, s);
        final BorderSide? border = _resolveBorder(cs, s);

        final Widget core = AnimatedContainer(
          duration: motion.duration,
          curve: motion.curve,
          height: _height,
          padding: EdgeInsets.symmetric(
            horizontal: isText ? FrostedSpacing.sp3 + 2 : FrostedSpacing.sp5,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: _shape(s),
            border: border != null ? Border.fromBorderSide(border) : null,
          ),
          child: Row(
            mainAxisSize:
                expanded ? MainAxisSize.max : MainAxisSize.min,
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
      _ButtonVariant.filled => cs.primary,
      _ButtonVariant.tonal => cs.secondaryContainer,
      _ButtonVariant.outlined => Colors.transparent,
      _ButtonVariant.text => Colors.transparent,
    };
    final Color overlayBase = switch (_variant) {
      _ButtonVariant.filled => cs.onPrimary,
      _ButtonVariant.tonal => cs.onSecondaryContainer,
      _ButtonVariant.outlined => cs.primary,
      _ButtonVariant.text => cs.primary,
    };
    final double alpha = _overlayAlpha(s);
    if (alpha == 0) return base;
    return Color.alphaBlend(overlayBase.withValues(alpha: alpha), base);
  }

  Color _resolveFg(ColorScheme cs, InteractionStates s) {
    if (!s.enabled) {
      return cs.onSurface.withValues(alpha: 0.38);
    }
    return switch (_variant) {
      _ButtonVariant.filled => cs.onPrimary,
      _ButtonVariant.tonal => cs.onSecondaryContainer,
      _ButtonVariant.outlined => cs.primary,
      _ButtonVariant.text => cs.primary,
    };
  }

  BorderSide? _resolveBorder(ColorScheme cs, InteractionStates s) {
    if (_variant != _ButtonVariant.outlined) return null;
    if (!s.enabled) {
      return BorderSide(color: cs.onSurface.withValues(alpha: 0.12));
    }
    final Color color = s.focused ? cs.primary : cs.outline;
    return BorderSide(color: color);
  }

  double _overlayAlpha(InteractionStates s) {
    if (s.pressed) return 0.12;
    if (s.focused) return 0.10;
    if (s.hovered) return 0.08;
    return 0;
  }
}
