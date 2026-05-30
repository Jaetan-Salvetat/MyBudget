import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_type_scale.dart';

/// Visual variants of [FrostedTextField].
enum FrostedTextFieldVariant {
  /// Solid container with a static label above and a bottom underline that
  /// turns primary on focus.
  filled,

  /// Transparent body with a 1px outline and a label that floats into the
  /// border.
  outlined,
}

/// An M3 Expressive single- or multi-line text input.
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
    this.onChanged,
    this.onSubmitted,
    this.variant = FrostedTextFieldVariant.filled,
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
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FrostedTextFieldVariant variant;

  @override
  State<FrostedTextField> createState() => _FrostedTextFieldState();
}

class _FrostedTextFieldState extends State<FrostedTextField> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _focused = false;

  // Mockup: `.field label` — 500 / 11px / letter-spacing 0.03em, sentence case.
  static const TextStyle _labelStyle = TextStyle(
    fontFamily: 'Geist',
    package: 'frosted_ui',
    fontWeight: FontWeight.w500,
    fontSize: 11,
    height: 1,
    letterSpacing: 0.33,
  );

  // Mockup: `.field .hint` — 400 / 11px / 1.3.
  static const TextStyle _hintTextStyle = TextStyle(
    fontFamily: 'Geist',
    package: 'frosted_ui',
    fontWeight: FontWeight.w400,
    fontSize: 11,
    height: 1.3,
  );

  bool get _hasError => widget.errorText != null;
  bool get _isOutlined => widget.variant == FrostedTextFieldVariant.outlined;

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
    return _isOutlined ? _buildOutlined(context) : _buildFilled(context);
  }

  Widget _buildFilled(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color underline = !widget.enabled
        ? cs.onSurface.withValues(alpha: 0.12)
        : _hasError
            ? cs.error
            : _focused
                ? cs.primary
                : cs.outlineVariant;

    // Mockup: padding 10px 14px, radius 8 8 0 0, bottom border 2px.
    final Widget body = Container(
      decoration: BoxDecoration(
        color: widget.enabled
            ? cs.surfaceContainerHigh
            : cs.onSurface.withValues(alpha: 0.04),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(FrostedRadius.sm),
        ),
        border: Border(
          bottom: BorderSide(color: underline, width: 2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: _input(cs),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.label != null) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              widget.label!,
              style: _labelStyle.copyWith(
                color: _hasError ? cs.error : cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
        body,
        _hint(cs),
      ],
    );
  }

  Widget _buildOutlined(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color border = !widget.enabled
        ? cs.onSurface.withValues(alpha: 0.12)
        : _hasError
            ? cs.error
            : _focused
                ? cs.primary
                : cs.outline;

    // Mockup: label floats on the border (notch), always primary / error.
    final Color labelColor = _hasError ? cs.error : cs.primary;

    // padding 12px 14px, radius 8, border 1px (2px on focus).
    final Widget box = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FrostedRadius.sm),
        border: Border.all(
          color: border,
          width: _focused || _hasError ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: _input(cs),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            box,
            if (widget.label != null)
              Positioned(
                top: -6,
                left: 12,
                child: Container(
                  color: cs.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    widget.label!,
                    style: _labelStyle.copyWith(color: labelColor),
                  ),
                ),
              ),
          ],
        ),
        _hint(cs),
      ],
    );
  }

  Widget _input(ColorScheme cs) {
    final TextField field = TextField(
      controller: widget.controller,
      focusNode: _focusNode,
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
      // Mockup: input text 400 / 15px.
      style: FrostedTypeScale.bodyMedium.copyWith(color: cs.onSurface),
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: widget.hintText,
        hintStyle: FrostedTypeScale.bodyMedium
            .copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
      ),
    );

    if (widget.leadingIcon == null && widget.trailingIcon == null) {
      return field;
    }
    return Row(
      children: <Widget>[
        if (widget.leadingIcon != null) ...<Widget>[
          Icon(widget.leadingIcon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
        ],
        Expanded(child: field),
        if (widget.trailingIcon != null) ...<Widget>[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: widget.enabled ? widget.onTrailingTap : null,
            behavior: HitTestBehavior.opaque,
            child: Icon(widget.trailingIcon, size: 20, color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  Widget _hint(ColorScheme cs) {
    final String? text = widget.errorText ?? widget.helperText;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 14, top: 4),
      child: Text(
        text,
        style: _hintTextStyle.copyWith(
          color: _hasError ? cs.error : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
