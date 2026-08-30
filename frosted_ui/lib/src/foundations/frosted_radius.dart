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

  static const List<double> scale = <double>[none, xs, sm, md, lg, xl, xxl];

  static double stepDown(double radius) {
    double result = none;
    for (final double token in scale) {
      if (token < radius) result = token;
    }
    return result;
  }
}
