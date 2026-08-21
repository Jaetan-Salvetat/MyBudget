import 'package:flutter/material.dart';

import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import 'frosted_field_surface.dart';

/// A read-only, field-styled trigger used by the date and time pickers.
///
/// Mirrors [FrostedTextField]'s look (label above a filled block with a focus
/// ring) but is read-only; tapping it runs [onTap]. Set [glass] for the
/// translucent veil (off-spec, opt-in).
class FrostedPickerField extends StatelessWidget {
  const FrostedPickerField({
    required this.icon,
    required this.onTap,
    this.label,
    this.hintText,
    this.text,
    this.enabled = true,
    this.glass = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final String? hintText;
  final String? text;
  final bool enabled;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool hasValue = text != null;
    final Color accent = enabled
        ? cs.onSurfaceVariant
        : cs.onSurface.withValues(alpha: 0.38);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(left: FrostedSpacing.sp1),
            child: Text(
              label!,
              style: FrostedTypeScale.labelMedium.copyWith(color: accent),
            ),
          ),
          const SizedBox(height: FrostedSpacing.sp2),
        ],
        GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: FrostedFieldSurface(
            focused: false,
            hasError: false,
            enabled: enabled,
            glass: glass,
            padding: const EdgeInsets.symmetric(
              horizontal: FrostedSpacing.sp4,
              vertical: FrostedSpacing.sp3,
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 20, color: accent),
                const SizedBox(width: FrostedSpacing.sp3),
                Expanded(
                  child: Text(
                    hasValue ? text! : (hintText ?? ''),
                    style: FrostedTypeScale.bodyLarge.copyWith(
                      color: hasValue ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
