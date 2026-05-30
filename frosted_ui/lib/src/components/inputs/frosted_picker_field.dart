import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';

/// A read-only, field-styled trigger used by the date and time pickers.
///
/// Renders the filled text-field look with a leading icon; tapping it runs
/// [onTap]. Not exported on its own — composed by `FrostedDateField` and
/// `FrostedTimeField`.
class FrostedPickerField extends StatelessWidget {
  const FrostedPickerField({
    required this.icon,
    required this.onTap,
    this.label,
    this.hintText,
    this.text,
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final String? hintText;
  final String? text;
  final bool enabled;

  static const double _height = 48;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool hasValue = text != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(
              left: FrostedSpacing.sp4,
              bottom: FrostedSpacing.sp1,
            ),
            child: Text(
              label!,
              style: FrostedTypeScale.labelMedium
                  .copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
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
                      ? cs.onSurfaceVariant
                      : cs.onSurface.withValues(alpha: 0.12),
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 20, color: cs.onSurfaceVariant),
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
