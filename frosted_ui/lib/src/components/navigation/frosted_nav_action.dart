import 'package:flutter/widgets.dart';

/// A command sitting in a navigation container next to its destinations.
///
/// Unlike a [FrostedNavItem] it takes part in no selection: it fires a
/// callback and, when it opens something that stays open, reports it through
/// [active]. Containers give it the accent fill so it reads as the one command
/// among the destinations, and never as a fourth of them.
class FrostedNavAction {
  const FrostedNavAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.activeIcon,
    this.active = false,
  });

  /// Icon shown while the action is at rest.
  final IconData icon;

  /// Icon shown while [active]. Falls back to [icon] when not provided.
  final IconData? activeIcon;

  /// Accessibility label. Never painted — the slot stays icon-only so the
  /// action cannot be mistaken for a destination.
  final String label;

  final VoidCallback onPressed;

  /// Whether whatever this action opens is currently showing.
  final bool active;
}
