import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../primitives/frosted_glass.dart';
import '../../primitives/frosted_glass_level.dart';
import '../actions/_interactive_surface.dart';
import 'frosted_badge.dart';
import 'frosted_nav_item.dart';

/// A Liquid Glass side drawer.
///
/// Drop directly into `Scaffold.drawer`. The drawer renders its content on a
/// glass material; a [header] and [footer] slot accept any widget. Items are
/// resolved via [currentIndex] / [onTap].
class FrostedDrawer extends StatelessWidget {
  const FrostedDrawer({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.header,
    this.footer,
    this.width = 296,
    this.level = FrostedGlassLevel.thick,
    this.tone = FrostedGlassTone.auto,
    super.key,
  });

  final List<FrostedNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget? header;
  final Widget? footer;
  final double width;
  final FrostedGlassLevel level;
  final FrostedGlassTone tone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(FrostedSpacing.sp3),
        child: SizedBox(
          width: width,
          child: FrostedGlass(
            level: level,
            tone: tone,
            borderRadius: BorderRadius.circular(FrostedRadius.xxl),
            padding: const EdgeInsets.all(FrostedSpacing.sp3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (header != null) ...<Widget>[
                  header!,
                  const SizedBox(height: FrostedSpacing.sp3),
                ],
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: FrostedSpacing.sp1),
                    itemBuilder: (BuildContext context, int index) {
                      return _DrawerItem(
                        item: items[index],
                        selected: index == currentIndex,
                        onTap: () => onTap(index),
                      );
                    },
                  ),
                ),
                if (footer != null) ...<Widget>[
                  const SizedBox(height: FrostedSpacing.sp3),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
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
    final Color bg = selected ? cs.primaryContainer : Colors.transparent;
    final Color fg = selected ? cs.onPrimaryContainer : cs.onSurface;
    final IconData icon = selected && item.selectedIcon != null
        ? item.selectedIcon!
        : item.icon;

    return InteractiveSurface(
      onTap: onTap,
      semanticsLabel: item.label,
      semanticsSelected: selected,
      builder: (BuildContext context, InteractionStates s) => DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(FrostedRadius.md),
        ),
        child: s.ink(
          borderRadius: BorderRadius.circular(FrostedRadius.md),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FrostedSpacing.sp3,
              vertical: FrostedSpacing.sp3,
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 20, color: fg),
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
          ),
        ),
      ),
    );
  }
}
