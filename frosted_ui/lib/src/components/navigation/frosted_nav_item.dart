import 'package:flutter/widgets.dart';

import 'frosted_badge.dart';

class FrostedNavItem {
  const FrostedNavItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.badge,
    this.tooltip,
  });

  final IconData icon;

  final IconData? selectedIcon;

  final String label;

  final FrostedBadge? badge;

  final String? tooltip;
}
