import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '../navigation/frosted_menu.dart';
import 'frosted_field_surface.dart';

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

class FrostedDropdown<T> extends StatefulWidget {
  const FrostedDropdown({
    required this.items,
    required this.value,
    required this.onChanged,
    this.label,
    this.hintText,
    this.enabled = true,
    this.glass = false,
    super.key,
  });

  final List<FrostedDropdownItem<T>> items;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String? label;
  final String? hintText;
  final bool enabled;
  final bool glass;

  @override
  State<FrostedDropdown<T>> createState() => _FrostedDropdownState<T>();
}

class _FrostedDropdownState<T> extends State<FrostedDropdown<T>> {
  static const Radius _corner = Radius.circular(FrostedRadius.md);
  static const double _viewportMargin = FrostedSpacing.sp4;

  final MenuController _controller = MenuController();
  final GlobalKey _fieldKey = GlobalKey();
  bool _open = false;
  double? _menuMaxHeight;

  double? get _fieldWidth {
    final RenderBox? box =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.size.width;
  }

  static const BorderRadius _radius = BorderRadius.all(_corner);

  void _measureRoom() {
    final RenderBox? box =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final MediaQueryData media = MediaQuery.of(context);
    final double obstructed = math.max(
      media.viewPadding.bottom,
      media.viewInsets.bottom,
    );
    final double fieldTop = box.localToGlobal(Offset.zero).dy;
    final double margin = _viewportMargin + FrostedMenuPanel.anchorGap;
    final double below =
        media.size.height - obstructed - margin - (fieldTop + box.size.height);
    final double above = fieldTop - media.viewPadding.top - margin;

    _menuMaxHeight = math.max(0, math.max(below, above));
  }

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
      _measureRoom();
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
        if (widget.label != null) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(left: FrostedSpacing.sp1),
            child: Text(
              widget.label!,
              style: FrostedTypeScale.labelMedium.copyWith(color: accent),
            ),
          ),
          const SizedBox(height: FrostedSpacing.sp2),
        ],
        MenuAnchor(
          controller: _controller,
          alignmentOffset: FrostedMenuPanel.anchorOffset,
          style: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Colors.transparent),
            elevation: WidgetStatePropertyAll<double>(0),
            padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.zero),
            shadowColor: WidgetStatePropertyAll<Color>(Colors.transparent),
            surfaceTintColor: WidgetStatePropertyAll<Color>(Colors.transparent),
          ),
          onClose: () => setState(() => _open = false),
          menuChildren: <Widget>[
            FrostedMenuPanel(
              width: _fieldWidth,
              maxHeight: _menuMaxHeight,
              borderRadius: _radius,
              entries: <FrostedMenuEntry>[
                for (final FrostedDropdownItem<T> item in widget.items)
                  FrostedMenuEntry(
                    label: item.label,
                    icon: item.icon,
                    selected: item.value == widget.value,
                    onTap: () {
                      widget.onChanged?.call(item.value);
                      _controller.close();
                    },
                  ),
              ],
            ),
          ],
          builder:
              (BuildContext context, MenuController controller, Widget? _) {
                return GestureDetector(
                  key: _fieldKey,
                  onTap: enabled ? _toggle : null,
                  behavior: HitTestBehavior.opaque,
                  child: FrostedFieldSurface(
                    focused: false,
                    hasError: false,
                    enabled: enabled,
                    glass: widget.glass,
                    borderRadius: _radius,
                    padding: const EdgeInsets.symmetric(
                      horizontal: FrostedSpacing.sp4,
                      vertical: FrostedSpacing.sp3,
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
