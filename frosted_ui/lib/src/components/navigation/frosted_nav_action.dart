import 'package:flutter/widgets.dart';

/// A command sitting in a navigation container next to its destinations.
///
/// Unlike a [FrostedNavItem] it takes part in no selection: it just fires a
/// callback. Containers give it the accent fill so it reads as the one thing
/// to press among the destinations, and never as one more of them.
class FrostedNavAction {
  const FrostedNavAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;

  /// Accessibility label. Never painted — the slot stays icon-only so the
  /// action cannot be mistaken for a destination.
  final String label;

  final VoidCallback onPressed;
}
