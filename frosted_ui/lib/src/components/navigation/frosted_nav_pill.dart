import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../primitives/frosted_glass.dart';
import '../../primitives/frosted_glass_level.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '../actions/_interactive_surface.dart';
import 'frosted_badge.dart';
import 'frosted_nav_action.dart';
import 'frosted_nav_item.dart';

const double _kMinTapTarget = 48;

const double _kSelectedTintLight = 0.18;

const double _kIconSize = 24;
const double _kSelectedTintDark = 0.30;

class FrostedNavPill extends StatelessWidget {
  const FrostedNavPill({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.action,
    super.key,
  });

  final List<FrostedNavItem> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  final FrostedNavAction? action;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      widthFactor: 1,
      heightFactor: 1,
      child: FrostedGlass(
        level: FrostedGlassLevel.thin,
        tone: FrostedGlassTone.auto,
        elevation: FrostedGlassElevation.floating,
        borderRadius: BorderRadius.circular(FrostedRadius.full),
        padding: const EdgeInsets.all(FrostedSpacing.sp1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < destinations.length; i++)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : FrostedSpacing.sp1),
                child: _NavPillDestination(
                  item: destinations[i],
                  selected: i == selectedIndex,
                  onTap: () => onDestinationSelected(i),
                ),
              ),
            if (action != null) ...<Widget>[
              const SizedBox(width: FrostedSpacing.sp2),
              _NavPillAction(action: action!),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavPillAction extends StatelessWidget {
  const _NavPillAction({required this.action});

  final FrostedNavAction action;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return InteractiveSurface(
      onTap: action.onPressed,
      semanticsLabel: action.label,
      builder: (BuildContext context, InteractionStates s) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
        child: SizedBox.square(
          dimension: _kMinTapTarget,
          child: s.ink(
            Center(
              child: Icon(action.icon, size: _kIconSize, color: cs.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavPillDestination extends StatelessWidget {
  const _NavPillDestination({
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

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background = selected
        ? cs.primary.withValues(
            alpha: isDark ? _kSelectedTintDark : _kSelectedTintLight,
          )
        : Colors.transparent;
    final Color foreground = selected
        ? cs.primary
        : cs.onSurface.withValues(alpha: 0.65);
    final IconData icon = selected && item.selectedIcon != null
        ? item.selectedIcon!
        : item.icon;

    return InteractiveSurface(
      onTap: onTap,
      semanticsLabel: item.label,
      semanticsSelected: selected,
      builder: (BuildContext context, InteractionStates s) => AnimatedContainer(
        duration: motion.duration,
        curve: motion.curve,
        constraints: const BoxConstraints(
          minWidth: _kMinTapTarget,
          minHeight: _kMinTapTarget,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(FrostedRadius.full),
        ),
        child: s.ink(
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: selected ? FrostedSpacing.sp4 : FrostedSpacing.sp2,
            ),
            child: AnimatedSize(
              duration: motion.duration,
              curve: motion.curve,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _IconWithBadge(
                    icon: icon,
                    color: foreground,
                    badge: item.badge,
                  ),
                  if (selected) ...<Widget>[
                    const SizedBox(width: FrostedSpacing.sp2),
                    Text(
                      item.label,
                      style: text.labelMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
    final Widget iconWidget = Icon(icon, size: _kIconSize, color: color);
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
