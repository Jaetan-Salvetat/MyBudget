import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

class QuickAddLoadingCard extends StatelessWidget {
  const QuickAddLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FrostedGlass(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      borderRadius: BorderRadius.circular(FrostedRadius.xl),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lecture en cours…',
                  style: TextStyle(
                    fontSize: 14,
                    height: 18 / 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "L'IA analyse ta saisie",
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _Dots(color: scheme.primary),
        ],
      ),
    );
  }
}

class _Dots extends StatefulWidget {
  final Color color;

  const _Dots({required this.color});

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value - i * 0.15) % 1.0;
            final scale = phase < 0.4
                ? 0.6 + (phase / 0.4) * 0.4
                : phase < 0.8
                ? 1.0 - ((phase - 0.4) / 0.4) * 0.4
                : 0.6;
            final opacity = phase < 0.4
                ? 0.4 + (phase / 0.4) * 0.6
                : phase < 0.8
                ? 1.0 - ((phase - 0.4) / 0.4) * 0.6
                : 0.4;
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
