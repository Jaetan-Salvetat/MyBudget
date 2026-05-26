import 'package:flutter/widgets.dart';

import 'frosted_badge.dart';

/// A single navigation entry inside a [FrostedSidebar].
///
/// Unlike [FrostedNavItem], sidebar items carry their own [id] and tap
/// callback — the sidebar layout is too heterogeneous to be addressed by a
/// single `currentIndex`.
class FrostedSidebarItem {
  const FrostedSidebarItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.leadingColor,
  });

  /// Stable identifier compared against `FrostedSidebar.selectedId`.
  final String id;

  /// Icon glyph shown to the left of [label].
  final IconData icon;

  final String label;

  final VoidCallback onTap;

  /// Optional badge rendered at the trailing edge.
  final FrostedBadge? badge;

  /// When non-null, replaces the leading [icon] with a colored dot (used by
  /// project lists, workspace markers, etc.).
  final Color? leadingColor;
}

/// A logical group of items inside a [FrostedSidebar].
class FrostedSidebarSection {
  const FrostedSidebarSection({required this.items, this.title});

  /// Optional section header (rendered as a small uppercase label).
  final String? title;

  final List<FrostedSidebarItem> items;
}
