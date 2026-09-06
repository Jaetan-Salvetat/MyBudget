import 'package:material_ui/material_ui.dart';

class FrostedBackground extends StatelessWidget {
  final Widget child;

  const FrostedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: scheme.surface),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-1, -1),
              radius: 0.55,
              colors: [
                scheme.primary.withValues(alpha: 0.14),
                Colors.transparent,
              ],
              stops: const [0.0, 0.7],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(1, 1),
              radius: 0.55,
              colors: [
                scheme.secondary.withValues(alpha: 0.16),
                Colors.transparent,
              ],
              stops: const [0.0, 0.7],
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
