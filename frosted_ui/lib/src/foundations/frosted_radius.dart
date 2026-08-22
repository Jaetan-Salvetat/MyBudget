/// Concentric corner-radius tokens used across Frosted UI.
///
/// Glass chrome uses [xxl]; cards default to [md]; pills/FAB use [full].
class FrostedRadius {
  const FrostedRadius._();

  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 28;
  static const double xxl = 34;
  static const double full = 9999;

  /// Every token on the scale, ascending. [full] is excluded — it is a
  /// sentinel for the pill form, not a step.
  static const List<double> scale = <double>[none, xs, sm, md, lg, xl, xxl];

  /// The token one step below [radius] on the [scale].
  ///
  /// A surface softens by exactly one step while pressed, which keeps the
  /// corner concentric with whatever contains it. An off-scale [radius] snaps
  /// to the largest token strictly below it; [none] is the floor.
  static double stepDown(double radius) {
    double result = none;
    for (final double token in scale) {
      if (token < radius) result = token;
    }
    return result;
  }
}
