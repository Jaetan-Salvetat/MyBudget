import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../actions/frosted_button.dart';

class FrostedBanner extends StatelessWidget {
  const FrostedBanner({
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FrostedSpacing.sp4,
        vertical: FrostedSpacing.sp3 + 2,
      ),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(FrostedRadius.lg),
      ),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 22, color: cs.onSecondaryContainer),
            const SizedBox(width: FrostedSpacing.sp3 + 2),
          ],
          Expanded(
            child: Text(
              message,
              style: FrostedTypeScale.bodyMedium.copyWith(
                color: cs.onSecondaryContainer,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(width: FrostedSpacing.sp2),
            FrostedButton.text(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
