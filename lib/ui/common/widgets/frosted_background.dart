import 'package:flutter/material.dart';

class FrostedBackground extends StatelessWidget {
  final Widget child;

  const FrostedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        gradient: RadialGradient(
          center: const Alignment(-1.0, -1.0),
          radius: 1.4,
          colors: [
            scheme.primary.withValues(alpha: 0.14),
            scheme.surface,
            scheme.secondary.withValues(alpha: 0.16),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: child,
    );
  }
}
