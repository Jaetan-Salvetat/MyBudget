import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_shape.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '_interactive_surface.dart';

enum _ButtonVariant { filled, tonal, outlined, text }

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

  final bool destructive;

  final FrostedShape shape;

  final _ButtonVariant _variant;

  static const double _height = 46;
  static const Size _box = Size(double.infinity, _height);

  static const Curve _arrivalCurve = Curves.easeInOutCubic;

  static const double _pressedOverlayAlpha = 0.12;
  static const double _pressedBareOverlayAlpha = 0.16;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotionTokens motionTokens = context.frostedTokens.motion;
    final bool isText = _variant == _ButtonVariant.text;

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
