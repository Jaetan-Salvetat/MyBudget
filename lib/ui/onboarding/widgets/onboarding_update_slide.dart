import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

class OnboardingUpdateSlide extends StatelessWidget {
  const OnboardingUpdateSlide({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FrostedCard(
            padding: const EdgeInsets.all(40),
            borderRadius: 40,
            child: Icon(
              CupertinoIcons.bell,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Restez à jour',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'MyBudget peut vérifier automatiquement si une nouvelle version est disponible et vous notifier.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
