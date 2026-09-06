import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_progress_tokens.dart';

class CircularProgressPainter extends CustomPainter {
  const CircularProgressPainter({
    required this.progress,
    required this.thickness,
    required this.rotation,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final double thickness;
  final double rotation;
  final Color color;
  final Color trackColor;

  static const double _startAngle = -math.pi / 2;
  static const double _turn = 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final double diameter = size.shortestSide;
    if (diameter <= thickness) return;

    final Rect arcRect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (diameter - thickness) / 2,
    );
    final double sweep = progress.clamp(0.0, 1.0) * _turn;
    final double gapSweep =
        (FrostedProgressTokens.circularTrackGap + thickness) /
        (math.pi * diameter) *
        _turn;
    final double gap = math.min(sweep, gapSweep);
    final double trackSweep = _turn - sweep - gap * 2;

    canvas.save();
    canvas.translate(arcRect.center.dx, arcRect.center.dy);
    canvas.rotate(rotation);
    canvas.translate(-arcRect.center.dx, -arcRect.center.dy);

    if (trackColor.a > 0 && trackSweep > 0) {
      canvas.drawArc(
        arcRect,
        _startAngle + sweep + gap,
        trackSweep,
        false,
        _stroke(trackColor),
      );
    }
    if (sweep > 0) {
      canvas.drawArc(arcRect, _startAngle, sweep, false, _stroke(color));
    }

    canvas.restore();
  }

  Paint _stroke(Color paintColor) => Paint()
    ..color = paintColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = thickness
    ..strokeCap = StrokeCap.round;

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.thickness != thickness ||
      oldDelegate.rotation != rotation ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
