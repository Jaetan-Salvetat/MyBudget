import 'package:flutter/material.dart';

import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';

/// A pill-shaped search input.
///
/// Opaque M3 content surface on `surfaceContainerHigh`, with a leading search
/// glyph and a trailing clear affordance that appears once text is entered.
class FrostedSearchField extends StatefulWidget {
  const FrostedSearchField({
    this.controller,
    this.hintText = 'Rechercher',
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    super.key,
  });

  final TextEditingController? controller;
  final String hintText;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  @override
  State<FrostedSearchField> createState() => _FrostedSearchFieldState();
}

class _FrostedSearchFieldState extends State<FrostedSearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();

  static const double _height = 48;
  static const double _radius = 14;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onChange() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool hasText = _controller.text.isNotEmpty;

    return Container(
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: widget.enabled
            ? cs.surfaceContainerHigh
            : cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.search, size: 22, color: cs.onSurfaceVariant),
          const SizedBox(width: FrostedSpacing.sp2),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              cursorColor: cs.primary,
              style: FrostedTypeScale.bodyLarge.copyWith(color: cs.onSurface),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: FrostedTypeScale.bodyLarge
                    .copyWith(color: cs.onSurfaceVariant),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (hasText) ...<Widget>[
            const SizedBox(width: FrostedSpacing.sp2),
            GestureDetector(
              onTap: _clear,
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.close, size: 20, color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
