import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../primitives/frosted_glass.dart';
import '../../primitives/frosted_glass_level.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import 'frosted_badge.dart';
import 'frosted_nav_item.dart';

/// A floating bottom navigation bar rendered as a Liquid Glass pill.
///
/// Active items are highlighted with a primary-container pill that grows
/// horizontally. Best used with 3-5 destinations.
class FrostedBottomBar extends StatelessWidget {
  const FrostedBottomBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.level = FrostedGlassLevel.regular,
    this.tone = FrostedGlassTone.auto,
    this.elevation = FrostedGlassElevation.floating,
    super.key,
  });

  final List<FrostedNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final FrostedGlassLevel level;
  final FrostedGlassTone tone;
  final FrostedGlassElevation elevation;

  @override
  Widget build(BuildContext context) {
    return FrostedGlass(
      level: level,
      tone: tone,
      elevation: elevation,
      borderRadius: BorderRadius.circular(FrostedRadius.full),
      padding: const EdgeInsets.all(FrostedSpacing.sp2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : FrostedSpacing.sp1),
              child: _TabBarItem(
                item: items[i],
                selected: i == currentIndex,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabBarItem extends StatelessWidget {
  const _TabBarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final FrostedNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;

    final Color background = selected
        ? cs.primaryContainer.withValues(alpha: 0.5)
        : Colors.transparent;
    final Color foreground = selected
        ? cs.onPrimaryContainer
        : cs.onSurface.withValues(alpha: 0.65);
    final IconData icon = selected && item.selectedIcon != null
        ? item.selectedIcon!
        : item.icon;

    return Semantics(
      button: true,
      label: item.label,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: motion.duration,
          curve: motion.curve,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? FrostedSpacing.sp5 : FrostedSpacing.sp4,
            vertical: FrostedSpacing.sp2,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(FrostedRadius.full),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _IconWithBadge(
                icon: icon,
                color: foreground,
                badge: item.badge,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: text.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({
    required this.icon,
    required this.color,
    required this.badge,
  });

  final IconData icon;
  final Color color;
  final FrostedBadge? badge;

  @override
  Widget build(BuildContext context) {
    final Widget iconWidget = Icon(icon, size: 22, color: color);
    if (badge == null) return iconWidget;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        iconWidget,
        Positioned(
          top: -2,
          right: -8,
          child: FrostedBadgeView(badge: badge!),
        ),
      ],
    );
  }
}
