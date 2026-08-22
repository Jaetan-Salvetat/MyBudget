import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '_interactive_surface.dart';

enum _ChipVariant { assist, filter, input, readOnly, suggestion }

/// A compact, label-driven control used for filtering, tagging, suggesting,
/// or triggering a contextual action.
class FrostedChip extends StatelessWidget {
  const FrostedChip._({
    super.key,
    required this.label,
    required _ChipVariant variant,
    this.icon,
    this.avatar,
    this.selected = false,
    this.onTap,
    this.onSelected,
    this.onDelete,
  }) : _variant = variant;

  /// Contextual action — never carries a selected state.
  factory FrostedChip.assist({
    Key? key,
    required String label,
    IconData? icon,
    required VoidCallback? onTap,
  }) => FrostedChip._(
    key: key,
    label: label,
    variant: _ChipVariant.assist,
    icon: icon,
    onTap: onTap,
  );

  /// On/off filter — shape morphs from rounded-rect to stadium when
  /// selected.
  factory FrostedChip.filter({
    Key? key,
    required String label,
    IconData? icon,
    Widget? avatar,
    required bool selected,
    required ValueChanged<bool>? onSelected,
  }) => FrostedChip._(
    key: key,
    label: label,
    variant: _ChipVariant.filter,
    icon: icon,
    avatar: avatar,
    selected: selected,
    onSelected: onSelected,
  );

  /// Input tag with optional avatar and a trailing close affordance.
  factory FrostedChip.input({
    Key? key,
    required String label,
    Widget? avatar,
    VoidCallback? onTap,
    VoidCallback? onDelete,
  }) => FrostedChip._(
    key: key,
    label: label,
    variant: _ChipVariant.input,
    avatar: avatar,
    onTap: onTap,
    onDelete: onDelete,
  );

  /// Settled value the user cannot act on — filled, never greyed out. Use it
  /// to display something the app has resolved, not something to tap.
  factory FrostedChip.readOnly({
    Key? key,
    required String label,
    IconData? icon,
  }) => FrostedChip._(
    key: key,
    label: label,
    variant: _ChipVariant.readOnly,
    icon: icon,
  );

  /// Suggested option — outlined, primary-tinted label.
  factory FrostedChip.suggestion({
    Key? key,
    required String label,
    required VoidCallback? onTap,
  }) => FrostedChip._(
    key: key,
    label: label,
    variant: _ChipVariant.suggestion,
    onTap: onTap,
  );

  final String label;
  final IconData? icon;
  final Widget? avatar;
  final bool selected;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onDelete;
  final _ChipVariant _variant;

  static const double _height = 32;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;

    final VoidCallback? tapHandler = switch (_variant) {
      _ChipVariant.filter =>
        onSelected == null ? null : () => onSelected!(!selected),
      _ChipVariant.readOnly => null,
      _ => onTap,
    };

    return InteractiveSurface(
      onTap: tapHandler,
      semanticsLabel: label,
      semanticsSelected: _variant == _ChipVariant.filter ? selected : null,
      builder: (BuildContext context, InteractionStates s) {
        final Color bg = _resolveBg(cs, s);
        final Color fg = _resolveFg(cs, s);
        final BorderSide? border = _resolveBorder(cs, s);

        return AnimatedContainer(
          duration: motion.duration,
          curve: motion.curve,
          height: _height,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: _shape(s),
            border: border != null ? Border.fromBorderSide(border) : null,
          ),
          child: s.ink(
            color: fg,
            borderRadius: _shape(s),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FrostedSpacing.sp3,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (_leading(fg) != null) ...<Widget>[
                    _leading(fg)!,
                    const SizedBox(width: FrostedSpacing.sp2),
                  ],
                  Text(
                    label,
                    style: FrostedTypeScale.labelLarge.copyWith(color: fg),
                  ),
                  if (_variant == _ChipVariant.input &&
                      onDelete != null) ...<Widget>[
                    const SizedBox(width: FrostedSpacing.sp2),
                    _DeleteAffordance(onDelete: onDelete!, color: fg),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget? _leading(Color fg) {
    if (_variant == _ChipVariant.filter && selected) {
      return Icon(Icons.check, size: 18, color: fg);
    }
    if (avatar != null) return avatar;
    if (icon != null) return Icon(icon, size: 18, color: fg);
    return null;
  }

  Color _resolveBg(ColorScheme cs, InteractionStates s) {
    if (_variant == _ChipVariant.readOnly) return cs.secondaryContainer;
    if (!s.enabled) return Colors.transparent;
    Color base;
    switch (_variant) {
      case _ChipVariant.filter:
        base = selected ? cs.secondaryContainer : Colors.transparent;
        break;
      case _ChipVariant.input:
        base = cs.surfaceContainerHighest;
        break;
      case _ChipVariant.readOnly:
        base = cs.secondaryContainer;
        break;
      case _ChipVariant.assist:
      case _ChipVariant.suggestion:
        base = Colors.transparent;
        break;
    }
    final Color overlay = _overlayBase(cs);
    final double alpha = _overlayAlpha(s);
    if (alpha == 0) return base;
    return Color.alphaBlend(overlay.withValues(alpha: alpha), base);
  }

  Color _resolveFg(ColorScheme cs, InteractionStates s) {
    if (_variant == _ChipVariant.readOnly) return cs.onSecondaryContainer;
    if (!s.enabled) return cs.onSurface.withValues(alpha: 0.38);
    switch (_variant) {
      case _ChipVariant.assist:
        return cs.onSurface;
      case _ChipVariant.filter:
        return selected ? cs.onSecondaryContainer : cs.onSurface;
      case _ChipVariant.input:
      case _ChipVariant.readOnly:
        return cs.onSurface;
      case _ChipVariant.suggestion:
        return cs.primary;
    }
  }

  BorderSide? _resolveBorder(ColorScheme cs, InteractionStates s) {
    switch (_variant) {
      case _ChipVariant.input:
      case _ChipVariant.readOnly:
        return null;
      case _ChipVariant.filter:
        if (selected) return null;
        return BorderSide(
          color: s.enabled ? cs.outline : cs.onSurface.withValues(alpha: 0.12),
        );
      case _ChipVariant.assist:
      case _ChipVariant.suggestion:
        return BorderSide(
          color: s.enabled ? cs.outline : cs.onSurface.withValues(alpha: 0.12),
        );
    }
  }

  BorderRadius _shape(InteractionStates s) {
    if (_variant == _ChipVariant.filter && selected) {
      return BorderRadius.circular(FrostedRadius.full);
    }
    return BorderRadius.circular(FrostedRadius.sm);
  }

  Color _overlayBase(ColorScheme cs) {
    switch (_variant) {
      case _ChipVariant.assist:
        return cs.onSurface;
      case _ChipVariant.filter:
        return selected ? cs.onSecondaryContainer : cs.onSurface;
      case _ChipVariant.input:
      case _ChipVariant.readOnly:
        return cs.onSurface;
      case _ChipVariant.suggestion:
        return cs.primary;
    }
  }

  double _overlayAlpha(InteractionStates s) {
    if (s.pressed) return 0.12;
    if (s.focused) return 0.10;
    if (s.hovered) return 0.08;
    return 0;
  }
}

/// The close target on an input chip. It carries its own surface so the ink
/// stays on the icon rather than washing the whole chip behind it.
class _DeleteAffordance extends StatelessWidget {
  const _DeleteAffordance({required this.onDelete, required this.color});

  final VoidCallback onDelete;
  final Color color;

  static const double _glyphSize = 16;

  @override
  Widget build(BuildContext context) {
    return InteractiveSurface(
      onTap: onDelete,
      builder: (BuildContext context, InteractionStates s) => s.ink(
        color: color,
        borderRadius: BorderRadius.circular(FrostedRadius.full),
        Icon(Icons.close, size: _glyphSize, color: color),
      ),
    );
  }
}
