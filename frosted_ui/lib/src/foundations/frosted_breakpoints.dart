/// M3-standard layout breakpoints, in logical pixels.
///
/// Reflects the four window-size classes used by Material 3's adaptive
/// guidance.
class FrostedBreakpoints {
  const FrostedBreakpoints._();

  /// Upper bound of the *compact* class (phone portrait). Below this, use
  /// a bottom tab bar.
  static const double compact = 600;

  /// Upper bound of the *medium* class (phone landscape / small tablet).
  /// Use a collapsed navigation rail in this band.
  static const double medium = 840;

  /// Upper bound of the *expanded* class (tablet / small desktop). Use an
  /// extended navigation rail in this band. Beyond this, prefer a sidebar.
  static const double expanded = 1240;
}
