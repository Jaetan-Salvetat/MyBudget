import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The ink a press throws off, expanding from the point touched.
///
/// Painted beneath [child], so it washes over the surface it sits on without
/// tinting the label above it. The animation is owned by the caller —
/// [InteractionStates.ripple] — which keeps this layer stateless and lets the
/// surface decide when a press starts.
class PressRipple extends StatelessWidget {
  const PressRipple({
    required this.origin,
    required this.progress,
    required this.color,
    required this.child,
    this.borderRadius,
    super.key,
  });

  /// Where the press landed, in the coordinates of [child]. A null origin —
  /// no press yet, or one that came from the keyboard — paints nothing.
  final Offset? origin;

  final Animation<double> progress;
  final Color color;

  /// The corners the ink is confined to. Null keeps it to the plain
  /// rectangle the surface occupies.
  final BorderRadius? borderRadius;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Offset? origin = this.origin;
    if (origin == null) return child;
    return CustomPaint(
      painter: _RipplePainter(
        origin: origin,
        progress: progress,
        color: color,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({
    required this.origin,
    required this.progress,
    required this.color,
    required this.borderRadius,
  }) : super(repaint: progress);

  final Offset origin;
  final Animation<double> progress;
  final Color color;
  final BorderRadius? borderRadius;

  static const double _peakAlpha = 0.18;
  static const Curve _growth = Curves.easeOutCubic;

  /// The ink keeps expanding while it thins out, so the circle is gone before
  /// it reaches the edge rather than snapping off mid-travel.
  static const double _fadeStart = 0.35;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = progress.value;
    if (t <= 0 || t >= 1) return;
    // The ink is painted, not layered, so nothing else keeps it inside the
    // surface — it clips itself to the shape it was handed.
    final Rect bounds = Offset.zero & size;
    canvas.save();
    final BorderRadius? borderRadius = this.borderRadius;
    if (borderRadius == null) {
      canvas.clipRect(bounds);
    } else {
      canvas.clipRRect(borderRadius.toRRect(bounds));
    }
    canvas.drawCircle(
      origin,
      _growth.transform(t) * _radiusToFarthestCorner(size),
      Paint()..color = color.withValues(alpha: _alphaAt(t)),
    );
    canvas.restore();
  }

  double _alphaAt(double t) {
    if (t <= _fadeStart) return _peakAlpha;
    return _peakAlpha * (1 - (t - _fadeStart) / (1 - _fadeStart));
  }

  double _radiusToFarthestCorner(Size size) {
    final double dx = math.max(origin.dx, size.width - origin.dx);
    final double dy = math.max(origin.dy, size.height - origin.dy);
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) =>
      oldDelegate.origin != origin ||
      oldDelegate.color != color ||
      oldDelegate.progress != progress ||
      oldDelegate.borderRadius != borderRadius;
}
