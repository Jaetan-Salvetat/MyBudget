import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

@immutable
class FrostedMotion {
  const FrostedMotion({required this.duration, required this.curve});

  final Duration duration;
  final Curve curve;
}

@immutable
class FrostedMotionTokens {
  const FrostedMotionTokens({
    required this.snappy,
    required this.fluid,
    required this.emphasized,
  });

  factory FrostedMotionTokens.standard() {
    return const FrostedMotionTokens(
      snappy: FrostedMotion(
        duration: Duration(milliseconds: 220),
        curve: Cubic(0.2, 0.9, 0.2, 1.0),
      ),
      fluid: FrostedMotion(
        duration: Duration(milliseconds: 420),
        curve: Cubic(0.32, 0.72, 0, 1),
      ),
      emphasized: FrostedMotion(
        duration: Duration(milliseconds: 500),
        curve: Cubic(0.2, 0, 0, 1),
      ),
    );
  }

  final FrostedMotion snappy;
  final FrostedMotion fluid;
  final FrostedMotion emphasized;

  FrostedMotionTokens copyWith({
    FrostedMotion? snappy,
    FrostedMotion? fluid,
    FrostedMotion? emphasized,
  }) {
    return FrostedMotionTokens(
      snappy: snappy ?? this.snappy,
      fluid: fluid ?? this.fluid,
      emphasized: emphasized ?? this.emphasized,
    );
  }

  static FrostedMotionTokens lerp(
    FrostedMotionTokens a,
    FrostedMotionTokens b,
    double t,
  ) {
    return t < 0.5 ? a : b;
  }
}
