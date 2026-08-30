import 'package:flutter/widgets.dart';

import 'frosted_badge.dart';

class FrostedSidebarItem {
  const FrostedSidebarItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.leadingColor,
  });

  final String id;

  final IconData icon;

  final String label;

  final VoidCallback onTap;

  final FrostedBadge? badge;

  final Color? leadingColor;
}

class FrostedSidebarSection {
  const FrostedSidebarSection({required this.items, this.title});

  final String? title;

  final List<FrostedSidebarItem> items;
}
