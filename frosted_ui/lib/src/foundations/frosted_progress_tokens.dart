import 'package:flutter/physics.dart';

class FrostedProgressTokens {
  const FrostedProgressTokens._();

  static const double linearThickness = 4;
  static const double linearTrackGap = 4;
  static const double linearStopSize = 4;
  static const double linearStopTrailingSpace = 6;
  static const double linearWidth = 240;

  static const double circularSize = 40;
  static const double circularThickness = 4;
  static const double circularTrackGap = 4;
  static const double circularIndeterminateMinSweep = 0.1;
  static const double circularIndeterminateMaxSweep = 0.87;

  static const double springStiffness = 50;
  static const double springDampingRatio = 1;

  static final SpringDescription progressSpring =
      SpringDescription.withDampingRatio(
        mass: 1,
        stiffness: springStiffness,
        ratio: springDampingRatio,
      );

  static const Tolerance progressTolerance = Tolerance(
    distance: 0.001,
    velocity: 0.001,
  );
}
