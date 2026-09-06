import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/theme/text_styles.dart';

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.eyebrowMono(
        color: color ?? theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
