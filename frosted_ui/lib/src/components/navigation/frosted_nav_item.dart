import 'package:flutter/widgets.dart';

import 'frosted_badge.dart';

/// A single navigation destination.
///
/// Used as input to [FrostedBottomBar], [FrostedNavigationRail], [FrostedDrawer]
/// and [FrostedSidebar]. The widgets that consume this model decide how to
/// render it — this class only carries data.
class FrostedNavItem {
  const FrostedNavItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.badge,
    this.tooltip,
  });

  /// Icon shown in the resting state.
  final IconData icon;

  /// Icon shown when this destination is selected. Falls back to [icon] if
  /// not provided.
  final IconData? selectedIcon;

  /// Visible label (also used as the accessibility label).
  final String label;

  /// Optional badge rendered next to the icon / label.
  final FrostedBadge? badge;

  /// Tooltip shown on hover. Defaults to [label] in containers that always
  /// surface tooltips (e.g. collapsed rail).
  final String? tooltip;
}
