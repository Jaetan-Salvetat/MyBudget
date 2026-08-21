import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'frosted_radius.dart';

/// The two forms an interactive surface can take, and the rule that morphs
/// between them on press.
///
/// A press always swaps the form for its [opposite]: a [pill] flattens into a
/// [rounded] rectangle, a [rounded] one rounds out into a pill. The inversion
/// is what carries the press — the surface never merely shrinks its corners,
/// it changes identity and comes back.
///
/// Radii are resolved against the physical box rather than taken from a
/// nominal token, so the interpolation between the two forms stays linear: a
/// [pill] is exactly half the shortest side, never a large sentinel value that
/// would spend most of the animation clamped and then snap at the end. On a
/// square box — an icon button — [pill] resolves to a circle.
enum FrostedShape {
  pill,
  rounded;

  /// The form this one morphs into while pressed.
  FrostedShape get opposite =>
      this == FrostedShape.pill ? FrostedShape.rounded : FrostedShape.pill;

  /// The corner radius this form takes on a box of [size].
  ///
  /// Both forms are capped at half the shortest side, the largest radius a box
  /// can carry before the corners overlap.
  double radiusFor(Size size) {
    final double capacity = size.shortestSide / 2;
    return switch (this) {
      FrostedShape.pill => capacity,
      FrostedShape.rounded => math.min(FrostedRadius.md, capacity),
    };
  }

  /// The corner radius for a box of [size] in the given interaction state.
  BorderRadius resolve(Size size, {required bool pressed}) => BorderRadius.all(
        Radius.circular((pressed ? opposite : this).radiusFor(size)),
      );
}
