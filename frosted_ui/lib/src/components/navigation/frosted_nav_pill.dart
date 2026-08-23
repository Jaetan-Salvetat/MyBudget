import 'package:flutter/material.dart';

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

/// Smallest square a destination may occupy, so a bare icon stays comfortably
/// tappable.
const double _kMinTapTarget = 48;

/// Accent strength of the selected destination's tint. Light surfaces need a
/// denser tint than dark ones: on a pale pill an M3 container tone lands
/// within a hair of the glass it sits on, so the selection disappears.
const double _kSelectedTintLight = 0.18;
const double _kSelectedTintDark = 0.30;

/// A compact Liquid Glass pill holding a handful of navigation destinations.
///
/// Only the selected destination spells out its label, inline next to its
/// icon; the others stay icon-only. The pill therefore hugs its content and
/// reads as a free-standing object floating over the page rather than as a bar
/// spanning it. Best used with 3-4 destinations — beyond that it grows wide
/// enough that [FrostedToolbar] or an edge-anchored bar carries the job better.
///
/// The pill claims no safe area of its own: whoever places it at the bottom of
/// a screen owns that inset, since the same widget also sits inside cards and
/// panels where no inset applies.
///
/// It sits on [FrostedGlassLevel.thin] on purpose. A bounded backdrop blur is
/// capped at a third of the surface's shortest span, so on a pill this short
/// every level from [FrostedGlassLevel.thin] up resolves to the very same
/// sigma — only the veil still differs. Reaching for a heavier level therefore
/// buys no extra blur and just paints a denser veil, which turns the pill into
/// an opaque slab instead of glass.
///
/// An optional [action] docks a command at the trailing edge, filled with the
/// accent so it reads as the one thing to press rather than as a fourth
/// destination.
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

  /// Command docked at the trailing edge, apart from the destinations.
  final FrostedNavAction? action;

  @override
  Widget build(BuildContext context) {
    // Hugging is the whole point of this pill, so it must survive a parent
    // that hands down a tight width — the `bottomNavigationBar` slot of a
    // Scaffold does exactly that. The Align absorbs the tight box and lets the
    // glass keep its own size inside it.
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
      builder: (BuildContext context, InteractionStates s) => DecoratedBox(
        decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
        child: SizedBox.square(
          dimension: _kMinTapTarget,
          child: s.ink(
            borderRadius: BorderRadius.circular(FrostedRadius.full),
            Center(child: Icon(action.icon, size: 22, color: cs.onPrimary)),
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
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(FrostedRadius.full),
        ),
        child: s.ink(
          borderRadius: BorderRadius.circular(FrostedRadius.full),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: selected ? FrostedSpacing.sp4 : FrostedSpacing.sp2,
            ),
            child: AnimatedSize(
              duration: motion.duration,
              curve: motion.curve,
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
