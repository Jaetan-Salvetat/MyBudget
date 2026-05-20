import 'package:flutter/material.dart';
import 'package:mybudget/core/theme/text_styles.dart';

class OnboardingSlide extends StatelessWidget {
  final String title;
  final String body;
  final Widget illustration;

  const OnboardingSlide({
    required this.title,
    required this.body,
    required this.illustration,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Center(child: illustration),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.displaySerifItalic(
                  fontSize: 36,
                  height: 40 / 36,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: TextStyle(
                  fontSize: 16,
                  height: 22 / 16,
                  fontWeight: FontWeight.w400,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
