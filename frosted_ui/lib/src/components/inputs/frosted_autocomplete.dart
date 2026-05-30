import 'package:flutter/material.dart';

import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../navigation/frosted_menu.dart';
import 'frosted_field_surface.dart';

/// A text field that filters [options] as the user types and surfaces the
/// matches in the shared Frosted menu overlay.
///
/// Opaque M3 content surface. Picking a suggestion fills the field and reports
/// it through [onSelected]. Set [glass] for the translucent veil (opt-in).
class FrostedAutocomplete extends StatefulWidget {
  const FrostedAutocomplete({
    required this.options,
    required this.onSelected,
    this.controller,
    this.label,
    this.hintText,
    this.leadingIcon,
    this.enabled = true,
    this.glass = false,
    this.maxSuggestions = 6,
    this.filter,
    this.focusNode,
    this.onChanged,
    super.key,
  });

  final List<String> options;
  final ValueChanged<String> onSelected;
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final IconData? leadingIcon;
  final bool enabled;
  final bool glass;
  final int maxSuggestions;

  /// Custom match test. Defaults to a case-insensitive "contains".
  final bool Function(String option, String query)? filter;

  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  @override
  State<FrostedAutocomplete> createState() => _FrostedAutocompleteState();
}

class _FrostedAutocompleteState extends State<FrostedAutocomplete> {
  final MenuController _menu = MenuController();
  final GlobalKey _fieldKey = GlobalKey();
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus != _focused) {
      setState(() => _focused = _focusNode.hasFocus);
    }
    if (!_focusNode.hasFocus) _menu.close();
  }

  double? get _fieldWidth {
    final RenderBox? box =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.size.width;
  }

  List<String> _matches(String query) {
    if (query.isEmpty) return const <String>[];
    final bool Function(String, String) test = widget.filter ??
        (String option, String q) =>
            option.toLowerCase().contains(q.toLowerCase());
    final List<String> hits = <String>[];
    for (final String option in widget.options) {
      if (test(option, query)) hits.add(option);
      if (hits.length >= widget.maxSuggestions) break;
    }
    return hits;
  }

  void _onChanged(String value) {
    widget.onChanged?.call(value);
    // setState first so menuChildren reflects the current query before the
    // menu shows — opening alone would surface the previous keystroke's hits.
    setState(() {});
    if (_matches(value).isEmpty) {
      _menu.close();
    } else if (!_menu.isOpen) {
      _menu.open();
    }
  }

  void _select(String value) {
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    widget.onSelected(value);
    _menu.close();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool enabled = widget.enabled;
    final Color accent = !enabled
        ? cs.onSurface.withValues(alpha: 0.38)
        : _focused
            ? cs.primary
            : cs.onSurfaceVariant;

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
          controller: _menu,
          style: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Colors.transparent),
            elevation: WidgetStatePropertyAll<double>(0),
            padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.zero),
            shadowColor: WidgetStatePropertyAll<Color>(Colors.transparent),
            surfaceTintColor:
                WidgetStatePropertyAll<Color>(Colors.transparent),
          ),
          menuChildren: <Widget>[
            FrostedMenuPanel(
              width: _fieldWidth,
              entries: <FrostedMenuEntry>[
                for (final String match in _matches(_controller.text))
                  FrostedMenuEntry(
                    label: match,
                    onTap: () => _select(match),
                  ),
              ],
            ),
          ],
          builder: (BuildContext context, MenuController controller, Widget? _) {
            return FrostedFieldSurface(
              key: _fieldKey,
              focused: _focused,
              hasError: false,
              enabled: enabled,
              glass: widget.glass,
              padding: const EdgeInsets.symmetric(
                horizontal: FrostedSpacing.sp4,
                vertical: FrostedSpacing.sp3,
              ),
              child: Row(
                children: <Widget>[
                  if (widget.leadingIcon != null) ...<Widget>[
                    Icon(widget.leadingIcon, size: 20, color: accent),
                    const SizedBox(width: FrostedSpacing.sp3),
                  ],
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: enabled,
                      onChanged: _onChanged,
                      onSubmitted: (String v) {
                        final List<String> hits = _matches(v);
                        if (hits.isNotEmpty) _select(hits.first);
                      },
                      cursorColor: cs.primary,
                      cursorWidth: 2,
                      cursorRadius: const Radius.circular(1),
                      style: FrostedTypeScale.bodyLarge
                          .copyWith(color: cs.onSurface),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: widget.hintText,
                        hintStyle: FrostedTypeScale.bodyLarge.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
