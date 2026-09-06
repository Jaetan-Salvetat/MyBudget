import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/theme/text_styles.dart';

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    required this.title,
    required this.body,
    required this.scene,
    super.key,
  });
  final String title;
  final String body;
  final Widget scene;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              FrostedSpacing.sp5,
              FrostedSpacing.sp4,
              FrostedSpacing.sp5,
              0,
            ),
            child: Center(child: scene),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FrostedSpacing.sp5,
            0,
            FrostedSpacing.sp5,
            FrostedSpacing.sp3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.displaySerifItalic(
                  fontSize: 34,
                  height: 38 / 34,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: FrostedSpacing.sp3),
              Text(
                body,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
