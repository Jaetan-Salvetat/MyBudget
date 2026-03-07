import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final String? subMessage;
  final IconData icon;
  final String buttonText;
  final VoidCallback onPressed;

  const EmptyState({
    super.key,
    required this.message,
    this.subMessage,
    this.icon = Icons.add_circle_outline,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(icon, size: 32, color: colorScheme.primary),
            ),
            const SizedBox(height: 24),

            Text(
              message,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            if (subMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                subMessage!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 32),
            FrostedFilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
