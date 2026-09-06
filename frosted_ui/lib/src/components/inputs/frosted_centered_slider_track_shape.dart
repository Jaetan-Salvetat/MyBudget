import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_slider_tokens.dart';

class FrostedCenteredSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  const FrostedCenteredSliderTrackShape();

  Rect activeRect(Rect trackRect, double thumbCenterX) {
    final double centerX = trackRect.center.dx;
    return Rect.fromLTRB(
      math.min(centerX, thumbCenterX),
      trackRect.top,
      math.max(centerX, thumbCenterX),
      trackRect.bottom,
    );
  }

  @override
  bool get isRounded => true;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final double? trackHeight = sliderTheme.trackHeight;
    if (trackHeight == null || trackHeight <= 0) return;

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final Paint activePaint = Paint()
      ..color = ColorTween(
        begin: sliderTheme.disabledActiveTrackColor,
        end: sliderTheme.activeTrackColor,
      ).evaluate(enableAnimation)!;
    final Paint inactivePaint = Paint()
      ..color = ColorTween(
        begin: sliderTheme.disabledInactiveTrackColor,
        end: sliderTheme.inactiveTrackColor,
      ).evaluate(enableAnimation)!;

    final Radius outerRadius = Radius.circular(trackRect.shortestSide / 2);
    const Radius innerRadius = Radius.circular(
      FrostedSliderTokens.trackInsideCornerRadius,
    );
    final double trackGap =
        sliderTheme.trackGap ?? FrostedSliderTokens.handleGap;
    final double gapStart = math.max(trackRect.left, thumbCenter.dx - trackGap);
    final double gapEnd = math.min(trackRect.right, thumbCenter.dx + trackGap);

    context.canvas
      ..save()
      ..clipRRect(RRect.fromRectAndRadius(trackRect, outerRadius));

    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        trackRect.left,
        trackRect.top,
        gapStart,
        trackRect.bottom,
        topLeft: outerRadius,
        bottomLeft: outerRadius,
        topRight: innerRadius,
        bottomRight: innerRadius,
      ),
      inactivePaint,
    );
    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        gapEnd,
        trackRect.top,
        trackRect.right,
        trackRect.bottom,
        topLeft: innerRadius,
        bottomLeft: innerRadius,
        topRight: outerRadius,
        bottomRight: outerRadius,
      ),
      inactivePaint,
    );

    final Rect active = activeRect(trackRect, thumbCenter.dx);
    final bool growsRight = thumbCenter.dx >= trackRect.center.dx;
    final Rect trimmed = growsRight
        ? Rect.fromLTRB(
            active.left,
            active.top,
            math.max(active.left, gapStart),
            active.bottom,
          )
        : Rect.fromLTRB(
            math.min(active.right, gapEnd),
            active.top,
            active.right,
            active.bottom,
          );
    if (trimmed.width > 0) {
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(trimmed, innerRadius),
        activePaint,
      );
    }

    context.canvas.restore();

    if (isDiscrete) return;
    _paintStopIndicator(
      context,
      trackRect,
      thumbCenter,
      activePaint,
      edge: true,
    );
    _paintStopIndicator(
      context,
      trackRect,
      thumbCenter,
      activePaint,
      edge: false,
    );
  }

  void _paintStopIndicator(
    PaintingContext context,
    Rect trackRect,
    Offset thumbCenter,
    Paint paint, {
    required bool edge,
  }) {
    final double trailing = trackRect.height / 2;
    final double dx = edge
        ? trackRect.right - trailing
        : trackRect.left + trailing;
    if ((thumbCenter.dx - dx).abs() < trailing) return;

    context.canvas.drawCircle(
      Offset(dx, trackRect.center.dy),
      FrostedSliderTokens.stopIndicatorSize / 2,
      paint,
    );
  }
}
