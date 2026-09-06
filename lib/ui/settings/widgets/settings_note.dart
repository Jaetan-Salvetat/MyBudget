import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';

class SettingsNote extends StatelessWidget {
  const SettingsNote({required this.icon, required this.text, super.key})
    : _prominent = false;

  const SettingsNote.prominent({
    required this.icon,
    required this.text,
    super.key,
  }) : _prominent = true;

  static const double iconSize = 18;

  final IconData icon;
  final String text;

  final bool _prominent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme typography = Theme.of(context).textTheme;
    final TextStyle? style = _prominent
        ? typography.bodyMedium
        : typography.bodySmall;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: iconSize, color: colors.onSurfaceVariant),
        const SizedBox(width: FrostedSpacing.sp3),
        Expanded(
          child: Text(
            text,
            style: style?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
