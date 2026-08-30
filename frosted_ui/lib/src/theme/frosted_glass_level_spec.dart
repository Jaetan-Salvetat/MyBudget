import 'dart:ui';

import 'package:flutter/foundation.dart';

@immutable
class FrostedGlassLevelSpec {
  const FrostedGlassLevelSpec({
    required this.blurSigma,
    required this.lightVeilOpacity,
    required this.darkVeilOpacity,
  });

  final double blurSigma;

  final double lightVeilOpacity;

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
