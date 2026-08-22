import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../primitives/frosted_glass.dart';
import '../../primitives/frosted_glass_level.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '../actions/_interactive_surface.dart';
import 'frosted_badge.dart';
import 'frosted_nav_item.dart';

const double _kCollapsedWidth = 80;
const double _kExtendedWidth = 256;

/// A vertical navigation rail for tablet-class layouts.
///
/// Toggles between a collapsed icon-only mode and an extended mode that
/// shows labels next to icons.
class FrostedNavigationRail extends StatelessWidget {
  const FrostedNavigationRail({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.extended = false,
    this.header,
    this.footer,
    this.level = FrostedGlassLevel.regular,
    this.tone = FrostedGlassTone.auto,
    super.key,
  });

  final List<FrostedNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool extended;
  final Widget? header;
  final Widget? footer;
  final FrostedGlassLevel level;
  final FrostedGlassTone tone;

  @override
  Widget build(BuildContext context) {
    final FrostedMotion motion = context.frostedTokens.motion.fluid;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(FrostedSpacing.sp3),
        child: AnimatedContainer(
          duration: motion.duration,
          curve: motion.curve,
          width: extended ? _kExtendedWidth : _kCollapsedWidth,
          child: FrostedGlass(
            level: level,
            tone: tone,
            borderRadius: BorderRadius.circular(FrostedRadius.xl),
            padding: const EdgeInsets.symmetric(
              vertical: FrostedSpacing.sp3,
              horizontal: FrostedSpacing.sp2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (header != null) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: FrostedSpacing.sp3),
                    child: header!,
                  ),
                ],
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      for (int i = 0; i < items.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            top: i == 0 ? 0 : FrostedSpacing.sp1,
                          ),
                          child: _RailItem(
                            item: items[i],
                            selected: i == currentIndex,
                            extended: extended,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
                  ),
                ),
                ?footer,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.item,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final FrostedNavItem item;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color bg = selected ? cs.primaryContainer : Colors.transparent;
    final Color fg = selected ? cs.onPrimaryContainer : cs.onSurface;
    final IconData icon = selected && item.selectedIcon != null
        ? item.selectedIcon!
        : item.icon;

    final Widget content = extended
        ? Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FrostedSpacing.sp3,
              vertical: FrostedSpacing.sp3,
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 22, color: fg),
                const SizedBox(width: FrostedSpacing.sp3),
                Expanded(
                  child: Text(
                    item.label,
                    style: FrostedTypeScale.labelLarge.copyWith(color: fg),
                  ),
                ),
                if (item.badge != null) FrostedBadgeView(badge: item.badge!),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.sp3),
            child: Column(
              children: <Widget>[
                _IconWithCornerBadge(icon: icon, color: fg, badge: item.badge),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: FrostedTypeScale.labelSmall.copyWith(color: fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );

    return Tooltip(
      message: extended ? '' : (item.tooltip ?? item.label),
      child: InteractiveSurface(
        onTap: onTap,
        semanticsLabel: item.label,
        semanticsSelected: selected,
        builder: (BuildContext context, InteractionStates s) => DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(FrostedRadius.lg),
          ),
          child: s.ink(
            color: fg,
            borderRadius: BorderRadius.circular(FrostedRadius.lg),
            content,
          ),
        ),
      ),
    );
  }
}

class _IconWithCornerBadge extends StatelessWidget {
  const _IconWithCornerBadge({
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
        Positioned(top: -2, right: -8, child: FrostedBadgeView(badge: badge!)),
      ],
    );
  }
}
