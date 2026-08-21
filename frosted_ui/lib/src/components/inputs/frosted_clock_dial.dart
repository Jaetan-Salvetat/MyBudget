import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../foundations/frosted_type_scale.dart';

/// Which unit the clock dial is currently editing.
enum FrostedClockUnit { hour, minute }

/// The M3 circular clock dial: a 256dp face where the user points at a number
/// to set the active unit. Drag or tap snaps to the nearest mark. Internal —
/// composed by the time picker.
class FrostedClockDial extends StatelessWidget {
  const FrostedClockDial({
    required this.unit,
    required this.hour,
    required this.minute,
    required this.onChanged,
    super.key,
  });

  final FrostedClockUnit unit;
  final int hour;
  final int minute;

  /// Reports the new value for the active [unit] as the user points around.
  final ValueChanged<int> onChanged;

  static const double _size = 256;
  static const double _handle = 48;

  bool get _isHour => unit == FrostedClockUnit.hour;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int value = _isHour ? hour : minute;
    // 24h hours sit on two rings (outer 1-12, inner 13-23/00). Minutes use a
    // single ring of 60, labelled every 5.
    final bool innerRing = _isHour && (value == 0 || value > 12);

    return SizedBox(
      width: _size,
      height: _size,
      child: GestureDetector(
        onPanStart: (DragStartDetails d) => _handlePoint(d.localPosition),
        onPanUpdate: (DragUpdateDetails d) => _handlePoint(d.localPosition),
        onTapDown: (TapDownDetails d) => _handlePoint(d.localPosition),
        child: CustomPaint(
          painter: _DialPainter(
            value: value,
            isHour: _isHour,
            innerRing: innerRing,
            faceColor: cs.surfaceContainerHighest,
            handleColor: cs.primary,
            onPrimary: cs.onPrimary,
            onSurface: cs.onSurface,
            labelStyle: FrostedTypeScale.bodyLarge,
          ),
        ),
      ),
    );
  }

  void _handlePoint(Offset local) {
    const Offset center = Offset(_size / 2, _size / 2);
    final Offset v = local - center;
    // Angle from 12 o'clock, clockwise.
    double angle = math.atan2(v.dx, -v.dy);
    if (angle < 0) angle += 2 * math.pi;

    if (_isHour) {
      int h = (angle / (2 * math.pi) * 12).round() % 12;
      final double radius = v.distance;
      final bool inner = radius < (_size / 2 - _handle);
      // Outer ring = 1..12, inner ring = 13..23 / 00.
      if (inner) {
        h = h == 0 ? 0 : h + 12;
      } else {
        h = h == 0 ? 12 : h;
      }
      onChanged(h % 24);
    } else {
      final int m = (angle / (2 * math.pi) * 60).round() % 60;
      onChanged(m);
    }
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.value,
    required this.isHour,
    required this.innerRing,
    required this.faceColor,
    required this.handleColor,
    required this.onPrimary,
    required this.onSurface,
    required this.labelStyle,
  });

  final int value;
  final bool isHour;
  final bool innerRing;
  final Color faceColor;
  final Color handleColor;
  final Color onPrimary;
  final Color onSurface;
  final TextStyle labelStyle;

  static const double _handle = 48;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double r = size.width / 2;
    final double outerR = r - _handle / 2;
    final double innerR = outerR - _handle;

    // Face.
    canvas.drawCircle(center, r, Paint()..color = faceColor);

    // Selector geometry.
    final double selectorR =
        isHour && innerRing ? innerR : outerR;
    final double angle = _angleFor(value);
    final Offset handleCenter = center +
        Offset(math.sin(angle) * selectorR, -math.cos(angle) * selectorR);

    // Track line + center dot + handle.
    final Paint accent = Paint()..color = handleColor;
    canvas.drawCircle(center, 4, accent);
    canvas.drawLine(
      center,
      handleCenter,
      Paint()
        ..color = handleColor
        ..strokeWidth = 2,
    );
    canvas.drawCircle(handleCenter, _handle / 2, accent);

    // Labels: position i (0 at top, clockwise).
    if (isHour) {
      // Outer ring: 12, 1, 2 … 11.  Inner ring: 00, 13, 14 … 23.
      for (int i = 0; i < 12; i++) {
        _drawLabel(canvas, center, outerR, i, i == 0 ? 12 : i);
        _drawLabel(canvas, center, innerR, i, i == 0 ? 0 : i + 12);
      }
    } else {
      // Minutes: a mark every 5.
      for (int i = 0; i < 12; i++) {
        _drawLabel(canvas, center, outerR, i, (i * 5) % 60, pad: true);
      }
    }
  }

  double _angleFor(int v) =>
      (isHour ? (v % 12) / 12 : v / 60) * 2 * math.pi;

  void _drawLabel(
    Canvas canvas,
    Offset center,
    double radius,
    int slot,
    int label, {
    bool pad = false,
  }) {
    final double angle = slot / 12 * 2 * math.pi;
    final Offset pos =
        center + Offset(math.sin(angle) * radius, -math.cos(angle) * radius);
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: pad ? label.toString().padLeft(2, '0') : label.toString(),
        style: labelStyle.copyWith(
          color: label == value ? onPrimary : onSurface,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.value != value || old.isHour != isHour || old.innerRing != innerRing;
}
