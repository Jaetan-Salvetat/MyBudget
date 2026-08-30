import 'package:material_ui/material_ui.dart';

class QuickAddShimmer extends StatefulWidget {
  static const Duration period = Duration(milliseconds: 1100);

  final Widget child;

  const QuickAddShimmer({required this.child, super.key});

  @override
  State<QuickAddShimmer> createState() => _QuickAddShimmerState();
}

class _QuickAddShimmerState extends State<QuickAddShimmer>
    with SingleTickerProviderStateMixin {
  static const double _bandWidth = 0.35;
  static const double _highlightAlpha = 0.55;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: QuickAddShimmer.period,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlight = Theme.of(context).colorScheme.onSurface;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final progress = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final start = -_bandWidth + progress * (1 + 2 * _bandWidth);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                highlight.withValues(alpha: _highlightAlpha),
                Colors.transparent,
              ],
              stops: [
                (start - _bandWidth / 2).clamp(0.0, 1.0),
                start.clamp(0.0, 1.0),
                (start + _bandWidth / 2).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}
