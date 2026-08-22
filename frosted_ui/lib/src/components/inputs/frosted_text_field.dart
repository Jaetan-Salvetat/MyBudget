import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import 'frosted_field_surface.dart';

/// A Frosted UI text input.
///
/// Original to the system — not a Material text field. The field is a single
/// self-contained filled block with its label baked in at the top; focus
/// raises a 2dp primary ring (the Glass Expressive focus signal) rather than
/// an underline or a notched outline.
///
/// Opaque M3 content surface — never glass. Pass [errorText] to drive the
/// error state; it takes priority over [helperText].
class FrostedTextField extends StatefulWidget {
  const FrostedTextField({
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.leadingIcon,
    this.trailingIcon,
    this.onTrailingTap,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.glass = false,
    super.key,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  /// Requests focus as soon as the field is mounted.
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Replaces the solid fill with a blurred translucent veil. Off-spec for
  /// content surfaces, so opt-in.
  final bool glass;

  @override
  State<FrostedTextField> createState() => _FrostedTextFieldState();
}

class _FrostedTextFieldState extends State<FrostedTextField> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _focused = false;

  bool get _hasError => widget.errorText != null;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus != _focused) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool enabled = widget.enabled;

    final Color accent = !enabled
        ? cs.onSurface.withValues(alpha: 0.38)
        : _hasError
        ? cs.error
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
        FrostedFieldSurface(
          focused: _focused,
          hasError: _hasError,
          enabled: enabled,
          glass: widget.glass,
          padding: const EdgeInsets.symmetric(
            horizontal: FrostedSpacing.sp4,
            vertical: FrostedSpacing.sp3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (widget.leadingIcon != null) ...<Widget>[
                Icon(widget.leadingIcon, size: 20, color: accent),
                const SizedBox(width: FrostedSpacing.sp3),
              ],
              Expanded(child: _input(cs)),
              if (widget.trailingIcon != null) ...<Widget>[
                const SizedBox(width: FrostedSpacing.sp3),
                GestureDetector(
                  onTap: enabled ? widget.onTrailingTap : null,
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    widget.trailingIcon,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (widget.errorText != null || widget.helperText != null)
          Padding(
            padding: const EdgeInsets.only(
              left: FrostedSpacing.sp4,
              top: FrostedSpacing.sp1,
            ),
            child: Text(
              widget.errorText ?? widget.helperText!,
              style: FrostedTypeScale.bodySmall.copyWith(
                color: _hasError ? cs.error : cs.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _input(ColorScheme cs) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      obscureText: widget.obscureText,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      cursorColor: cs.primary,
      cursorWidth: 2,
      cursorRadius: const Radius.circular(1),
      style: FrostedTypeScale.bodyLarge.copyWith(color: cs.onSurface),
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: widget.hintText,
        hintStyle: FrostedTypeScale.bodyLarge.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
