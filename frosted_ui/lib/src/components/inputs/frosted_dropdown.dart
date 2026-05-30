import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';

/// A single option in a [FrostedDropdown].
class FrostedDropdownItem<T> {
  const FrostedDropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// A field-styled single-select dropdown.
///
/// Opaque M3 content surface. Mirrors [FrostedTextField]'s filled look and
/// opens a menu of [items]; selecting one reports it through [onChanged].
class FrostedDropdown<T> extends StatefulWidget {
  const FrostedDropdown({
    required this.items,
    required this.value,
    required this.onChanged,
    this.label,
    this.hintText,
    this.enabled = true,
    super.key,
  });

  final List<FrostedDropdownItem<T>> items;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String? label;
  final String? hintText;
  final bool enabled;

  @override
  State<FrostedDropdown<T>> createState() => _FrostedDropdownState<T>();
}

class _FrostedDropdownState<T> extends State<FrostedDropdown<T>> {
  final MenuController _controller = MenuController();
  bool _open = false;

  static const double _height = 48;

  FrostedDropdownItem<T>? get _selected {
    for (final FrostedDropdownItem<T> item in widget.items) {
      if (item.value == widget.value) return item;
    }
    return null;
  }

  void _toggle() {
    if (_controller.isOpen) {
      _controller.close();
    } else {
      _controller.open();
    }
    setState(() => _open = _controller.isOpen);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;
    final bool enabled = widget.enabled;
    final FrostedDropdownItem<T>? selected = _selected;
    final Color accent = _open ? cs.primary : cs.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(
              left: FrostedSpacing.sp4,
              bottom: FrostedSpacing.sp1,
            ),
            child: Text(
              widget.label!,
              style: FrostedTypeScale.labelMedium.copyWith(color: accent),
            ),
          ),
        MenuAnchor(
          controller: _controller,
          style: MenuStyle(
            backgroundColor:
                WidgetStatePropertyAll<Color>(cs.surfaceContainerHigh),
            shape: WidgetStatePropertyAll<OutlinedBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FrostedRadius.md),
              ),
            ),
          ),
          onClose: () => setState(() => _open = false),
          menuChildren: <Widget>[
            for (final FrostedDropdownItem<T> item in widget.items)
              MenuItemButton(
                leadingIcon:
                    item.icon == null ? null : Icon(item.icon, size: 20),
                onPressed: () => widget.onChanged?.call(item.value),
                child: Text(item.label, style: FrostedTypeScale.bodyLarge),
              ),
          ],
          builder: (BuildContext context, MenuController controller, Widget? _) {
            return GestureDetector(
              onTap: enabled ? _toggle : null,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: motion.duration,
                curve: motion.curve,
                height: _height,
                padding:
                    const EdgeInsets.symmetric(horizontal: FrostedSpacing.sp4),
                decoration: BoxDecoration(
                  color: enabled
                      ? cs.surfaceContainerHigh
                      : cs.onSurface.withValues(alpha: 0.04),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(FrostedRadius.sm),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: enabled
                          ? accent
                          : cs.onSurface.withValues(alpha: 0.12),
                      width: _open ? 2 : 1,
                    ),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        selected?.label ?? widget.hintText ?? '',
                        style: FrostedTypeScale.bodyLarge.copyWith(
                          color: selected == null
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedRotation(
                      duration: motion.duration,
                      curve: motion.curve,
                      turns: _open ? 0.5 : 0,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 22,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
