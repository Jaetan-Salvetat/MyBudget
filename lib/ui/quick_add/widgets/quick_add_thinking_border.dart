import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';

/// A gradient sweeping along the border of the field while the model reads
/// the text : the field itself says it is thinking, no chip has to.
///
/// Pure stroke paint over the child — no backdrop involved, so the glass
/// underneath never greys out.
class QuickAddThinkingBorder extends StatefulWidget {
  static const Duration sweepPeriod = Duration(milliseconds: 1400);
  static const Duration fade = Duration(milliseconds: 240);

  final bool thinking;
  final Widget child;

  const QuickAddThinkingBorder({
    required this.thinking,
    required this.child,
    super.key,
  });

  @override
  State<QuickAddThinkingBorder> createState() => _QuickAddThinkingBorderState();
}

class _QuickAddThinkingBorderState extends State<QuickAddThinkingBorder>
    with TickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: QuickAddThinkingBorder.sweepPeriod,
  );
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: QuickAddThinkingBorder.fade,
  );

  @override
  void initState() {
    super.initState();
    _fade.addStatusListener(_onFadeStatus);
    if (widget.thinking) _show();
  }

  @override
  void didUpdateWidget(QuickAddThinkingBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.thinking == oldWidget.thinking) return;
    widget.thinking ? _show() : _fade.reverse();
  }

  void _show() {
    _sweep.repeat();
    _fade.forward();
  }

  /// The sweep only spins while there is something to see.
  void _onFadeStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) _sweep.stop();
  }

  @override
  void dispose() {
    _sweep.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: Listenable.merge([_sweep, _fade]),
              builder: (context, _) {
                if (_fade.value == 0) return const SizedBox.shrink();
                return RepaintBoundary(
                  child: CustomPaint(
                    painter: QuickAddThinkingBorderPainter(
                      progress: _sweep.value,
                      opacity: Curves.easeOut.transform(_fade.value),
                      headColor: scheme.tertiary,
                      tailColor: scheme.primary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Strokes the field's rounded rect with a rotating comet-shaped gradient.
class QuickAddThinkingBorderPainter extends CustomPainter {
  static const double strokeWidth = 2.5;
  static const double _cornerRadius = FrostedRadius.md;
  static const List<double> _stops = [0.0, 0.45, 0.7, 1.0];

  /// The whole ring shifts colour while the model reads : the comet alone
  /// would leave half the perimeter looking like the plain focus ring.
  static const double _baseRingAlpha = 0.45;

  /// The soft halo the comet drags along : without it the sweep disappears
  /// against the focus ring it runs on.
  static const double _glowStrokeWidth = 6;
  static const double _glowBlurSigma = 3;
  static const double _glowAlpha = 0.8;

  final double progress;
  final double opacity;
  final Color headColor;
  final Color tailColor;

  const QuickAddThinkingBorderPainter({
    required this.progress,
    required this.opacity,
    required this.headColor,
    required this.tailColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      const Radius.circular(_cornerRadius),
    );

    final basePaint = Paint()
      ..color = tailColor.withValues(alpha: _baseRingAlpha * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(rrect, basePaint);

    final gradient = SweepGradient(
      transform: GradientRotation(2 * math.pi * progress),
      colors: [
        tailColor.withValues(alpha: 0),
        tailColor.withValues(alpha: opacity),
        headColor.withValues(alpha: opacity),
        headColor.withValues(alpha: 0),
      ],
      stops: _stops,
    );
    final shader = gradient.createShader(rect);

    final glowPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = _glowStrokeWidth
      ..color = Colors.white.withValues(alpha: _glowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _glowBlurSigma);
    canvas.drawRRect(rrect, glowPaint);

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(QuickAddThinkingBorderPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        opacity != oldDelegate.opacity ||
        headColor != oldDelegate.headColor ||
        tailColor != oldDelegate.tailColor;
  }
}
