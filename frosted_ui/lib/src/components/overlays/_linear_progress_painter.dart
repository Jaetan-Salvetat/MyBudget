import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_progress_tokens.dart';

@immutable
class LinearProgressSegment {
  const LinearProgressSegment(this.tail, this.head);

  final double tail;
  final double head;

  @override
  bool operator ==(Object other) =>
      other is LinearProgressSegment &&
      other.tail == tail &&
      other.head == head;

  @override
  int get hashCode => Object.hash(tail, head);
}

class LinearProgressPainter extends CustomPainter {
  const LinearProgressPainter({
    required this.segments,
    required this.color,
    required this.trackColor,
    required this.showStopIndicator,
    required this.textDirection,
  });

  final List<LinearProgressSegment> segments;
  final Color color;
  final Color trackColor;
  final bool showStopIndicator;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    canvas.save();
    if (textDirection == TextDirection.rtl) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final double thickness = size.height;
    final StrokeCap cap = size.height > size.width
        ? StrokeCap.butt
        : StrokeCap.round;
    final double gap = _gapFraction(size, thickness);
    final Paint trackPaint = _stroke(trackColor, thickness, cap);
    final Paint activePaint = _stroke(color, thickness, cap);

    for (final LinearProgressSegment track in trackSegments(gap)) {
      _drawLine(canvas, size, track.tail, track.head, trackPaint);
    }

    for (final LinearProgressSegment segment in segments) {
      _drawLine(canvas, size, segment.tail, segment.head, activePaint);
    }

    if (showStopIndicator) _drawStopIndicator(canvas, size, thickness);

    canvas.restore();
  }

  @visibleForTesting
  List<LinearProgressSegment> trackSegments(double gap) {
    final List<LinearProgressSegment> tracks = <LinearProgressSegment>[];
    double cursor = 1;
    for (final LinearProgressSegment segment in segments) {
      final double leading = segment.head + math.min(segment.head, gap);
      if (cursor > leading) {
        tracks.add(LinearProgressSegment(leading, cursor));
      }
      cursor = segment.tail >= 1 ? 1 : segment.tail - gap;
    }
    if (cursor > 0) tracks.add(LinearProgressSegment(0, cursor));
    return tracks;
  }

  double _gapFraction(Size size, double thickness) {
    final double gap = size.height > size.width
        ? FrostedProgressTokens.linearTrackGap
        : FrostedProgressTokens.linearTrackGap + thickness;
    return gap / size.width;
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    double startFraction,
    double endFraction,
    Paint paint,
  ) {
    if (endFraction <= startFraction) return;

    final double y = size.height / 2;
    final double capOffset = paint.strokeCap == StrokeCap.butt
        ? 0
        : size.height / 2;
    final double start = (startFraction * size.width).clamp(
      capOffset,
      size.width - capOffset,
    );
    final double end = (endFraction * size.width).clamp(
      capOffset,
      size.width - capOffset,
    );
    canvas.drawLine(Offset(start, y), Offset(end, y), paint);
  }

  void _drawStopIndicator(Canvas canvas, Size size, double thickness) {
    final double stopSize = math.min(
      FrostedProgressTokens.linearStopSize,
      thickness,
    );
    final double trailingSpace = math.min(
      (thickness - stopSize) / 2,
      FrostedProgressTokens.linearStopTrailingSpace,
    );
    canvas.drawCircle(
      Offset(size.width - stopSize / 2 - trailingSpace, size.height / 2),
      stopSize / 2,
      Paint()..color = color,
    );
  }

  Paint _stroke(Color paintColor, double width, StrokeCap cap) => Paint()
    ..color = paintColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = cap;

  @override
  bool shouldRepaint(LinearProgressPainter oldDelegate) =>
      !listEquals(oldDelegate.segments, segments) ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.showStopIndicator != showStopIndicator ||
      oldDelegate.textDirection != textDirection;
}
