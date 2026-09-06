import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'frosted_radius.dart';

enum FrostedShape {
  pill,
  rounded;

  FrostedShape get opposite =>
      this == FrostedShape.pill ? FrostedShape.rounded : FrostedShape.pill;

  double radiusFor(Size size, {double roundedRadius = FrostedRadius.md}) {
    final double capacity = size.shortestSide / 2;
    return switch (this) {
      FrostedShape.pill => capacity,
      FrostedShape.rounded => math.min(roundedRadius, capacity),
    };
  }

  BorderRadius resolve(
    Size size, {
    required bool pressed,
    double roundedRadius = FrostedRadius.md,
  }) => BorderRadius.all(
    Radius.circular(
      (pressed ? opposite : this).radiusFor(size, roundedRadius: roundedRadius),
    ),
  );
}
