import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';

class FrostedFormField extends StatelessWidget {
  const FrostedFormField({
    required this.child,
    this.label,
    this.helperText,
    this.errorText,
    super.key,
  });

  final Widget child;
  final String? label;
  final String? helperText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(
            label!,
            style: FrostedTypeScale.labelMedium.copyWith(
              color: hasError ? cs.error : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: FrostedSpacing.sp2),
        ],
        child,
        if (errorText != null || helperText != null) ...<Widget>[
          const SizedBox(height: FrostedSpacing.sp1),
          Text(
            errorText ?? helperText!,
            style: FrostedTypeScale.bodySmall.copyWith(
              color: hasError ? cs.error : cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
