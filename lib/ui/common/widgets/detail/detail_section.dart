import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/theme/text_styles.dart';

class DetailSection extends StatelessWidget {
  const DetailSection({
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    super.key,
  });
  final String title;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8, left: 4, right: 4),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.mono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacingEm: 0.09,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        FrostedCard(padding: padding, child: child),
      ],
    );
  }
}
