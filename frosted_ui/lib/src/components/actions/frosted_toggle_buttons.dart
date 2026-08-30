import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '_interactive_surface.dart';

class FrostedToggleItem {
  const FrostedToggleItem({required this.icon, this.label, this.tooltip});

  final IconData icon;
  final String? label;
  final String? tooltip;
}

enum _ToggleVariant { connected, standard }

class FrostedToggleButtons extends StatelessWidget {
  const FrostedToggleButtons._({
    required this.items,
    required this.selected,
    required this.onChanged,
    required _ToggleVariant variant,
    required this.spacing,
    this.multiSelect = false,
    this.axis = Axis.horizontal,
    super.key,
  }) : _variant = variant;

  factory FrostedToggleButtons.connected({
    Key? key,
    required List<FrostedToggleItem> items,
    required Set<int> selected,
    required ValueChanged<Set<int>>? onChanged,
    bool multiSelect = false,
    Axis axis = Axis.horizontal,
  }) => FrostedToggleButtons._(
    key: key,
    items: items,
    selected: selected,
    onChanged: onChanged,
    variant: _ToggleVariant.connected,
    spacing: FrostedSpacing.sp05,
    multiSelect: multiSelect,
    axis: axis,
  );

  factory FrostedToggleButtons.standard({
    Key? key,
    required List<FrostedToggleItem> items,
    required Set<int> selected,
    required ValueChanged<Set<int>>? onChanged,
    bool multiSelect = false,
    Axis axis = Axis.horizontal,
    double spacing = FrostedSpacing.sp2,
  }) => FrostedToggleButtons._(
    key: key,
    items: items,
    selected: selected,
    onChanged: onChanged,
    variant: _ToggleVariant.standard,
    spacing: spacing,
    multiSelect: multiSelect,
    axis: axis,
  );

  final List<FrostedToggleItem> items;
  final Set<int> selected;
  final ValueChanged<Set<int>>? onChanged;
  final bool multiSelect;
  final Axis axis;
  final double spacing;
  final _ToggleVariant _variant;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onChanged != null;

    final List<Widget> children = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(
          axis == Axis.horizontal
              ? SizedBox(width: spacing)
              : SizedBox(height: spacing),
        );
      }
      children.add(
        _ToggleButton(
          item: items[i],
          variant: _variant,
          axis: axis,
          isFirst: i == 0,
          isLast: i == items.length - 1,
          selected: selected.contains(i),
          onTap: enabled ? () => _handleTap(i) : null,
        ),
      );
    }

    return axis == Axis.horizontal
        ? Row(mainAxisSize: MainAxisSize.min, children: children)
        : Column(mainAxisSize: MainAxisSize.min, children: children);
  }

  void _handleTap(int index) {
    final Set<int> next = <int>{...selected};
    if (multiSelect) {
      if (next.contains(index)) {
        next.remove(index);
      } else {
        next.add(index);
      }
    } else {
      next
        ..clear()
        ..add(index);
    }
    onChanged!(next);
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.item,
    required this.variant,
    required this.axis,
    required this.isFirst,
    required this.isLast,
    required this.selected,
    required this.onTap,
  });

  final FrostedToggleItem item;
  final _ToggleVariant variant;
  final Axis axis;
  final bool isFirst;
  final bool isLast;
  final bool selected;
  final VoidCallback? onTap;

  bool get _iconOnly => item.label == null;

  bool get _showsCheck =>
      variant == _ToggleVariant.connected && selected && !_iconOnly;

  static const double _height = 40;
  static const double _pill = _height / 2;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;

    return InteractiveSurface(
      onTap: onTap,
      semanticsLabel: item.tooltip ?? item.label,
      semanticsSelected: selected,
      builder: (BuildContext context, InteractionStates s) {
        final Color bg = _resolveBg(cs, s);
        final Color fg = _resolveFg(cs, s);

        Widget content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(_showsCheck ? Icons.check : item.icon, size: 20, color: fg),
            if (!_iconOnly) ...<Widget>[
              const SizedBox(width: FrostedSpacing.sp2),
              Text(
                item.label!,
                style: FrostedTypeScale.labelLarge.copyWith(color: fg),
              ),
            ],
          ],
        );

        if (item.tooltip != null && _iconOnly) {
          content = Tooltip(message: item.tooltip!, child: content);
        }

        return AnimatedContainer(
          duration: motion.duration,
          curve: motion.curve,
          height: _height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: _resolveBorderRadius(s),
          ),
          child: s.ink(
            Center(
              child: Padding(padding: _padding, child: content),
            ),
          ),
        );
      },
    );
  }

  EdgeInsets get _padding => _iconOnly
      ? const EdgeInsets.symmetric(horizontal: FrostedSpacing.sp3)
      : const EdgeInsets.symmetric(horizontal: FrostedSpacing.sp4);

  Color _resolveBg(ColorScheme cs, InteractionStates s) {
    if (!s.enabled) return cs.onSurface.withValues(alpha: 0.12);
    final Color base = selected ? cs.secondary : cs.secondaryContainer;
    final Color overlay = selected ? cs.onSecondary : cs.onSecondaryContainer;
    final double alpha = _overlayAlpha(s);
    if (alpha == 0) return base;
    return Color.alphaBlend(overlay.withValues(alpha: alpha), base);
  }

  Color _resolveFg(ColorScheme cs, InteractionStates s) {
    if (!s.enabled) return cs.onSurface.withValues(alpha: 0.38);
    return selected ? cs.onSecondary : cs.onSecondaryContainer;
  }

  BorderRadius _resolveBorderRadius(InteractionStates s) {
    if (variant == _ToggleVariant.standard) {
      if (selected) return BorderRadius.circular(_pill);
      return BorderRadius.circular(
        s.pressed ? FrostedRadius.xs : FrostedRadius.md,
      );
    }

    if (selected) return BorderRadius.circular(_pill);

    const double outer = _pill;
    final double inner = s.pressed ? FrostedRadius.xs : FrostedRadius.sm;

    if (isFirst && isLast) return BorderRadius.circular(outer);

    final Radius outerR = Radius.circular(outer);
    final Radius innerR = Radius.circular(inner);
    if (axis == Axis.horizontal) {
      if (isFirst) {
        return BorderRadius.horizontal(left: outerR, right: innerR);
      }
      if (isLast) {
        return BorderRadius.horizontal(left: innerR, right: outerR);
      }
    } else {
      if (isFirst) {
        return BorderRadius.vertical(top: outerR, bottom: innerR);
      }
      if (isLast) {
        return BorderRadius.vertical(top: innerR, bottom: outerR);
      }
    }
    return BorderRadius.circular(inner);
  }

  double _overlayAlpha(InteractionStates s) {
    if (s.pressed) return 0.12;
    if (s.focused) return 0.10;
    if (s.hovered) return 0.08;
    return 0;
  }
}
