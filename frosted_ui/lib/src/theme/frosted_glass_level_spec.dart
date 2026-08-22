import 'dart:ui';

import 'package:flutter/foundation.dart';

/// The numeric values driving a single [FrostedGlassLevel].
@immutable
class FrostedGlassLevelSpec {
  const FrostedGlassLevelSpec({
    required this.blurSigma,
    required this.lightVeilOpacity,
    required this.darkVeilOpacity,
  });

  /// Gaussian blur sigma applied to the backdrop.
  final double blurSigma;

  /// Opacity of the white veil placed over the blurred backdrop when the
  /// glass uses a light tone.
  final double lightVeilOpacity;

  /// Opacity of the black veil placed over the blurred backdrop when the
  /// glass uses a dark tone.
  final double darkVeilOpacity;

  FrostedGlassLevelSpec copyWith({
    double? blurSigma,
    double? lightVeilOpacity,
    double? darkVeilOpacity,
  }) {
    return FrostedGlassLevelSpec(
      blurSigma: blurSigma ?? this.blurSigma,
      lightVeilOpacity: lightVeilOpacity ?? this.lightVeilOpacity,
      darkVeilOpacity: darkVeilOpacity ?? this.darkVeilOpacity,
    );
  }

  static FrostedGlassLevelSpec lerp(
    FrostedGlassLevelSpec a,
    FrostedGlassLevelSpec b,
    double t,
  ) {
    return FrostedGlassLevelSpec(
      blurSigma: lerpDouble(a.blurSigma, b.blurSigma, t)!,
      lightVeilOpacity: lerpDouble(a.lightVeilOpacity, b.lightVeilOpacity, t)!,
      darkVeilOpacity: lerpDouble(a.darkVeilOpacity, b.darkVeilOpacity, t)!,
    );
  }
}
