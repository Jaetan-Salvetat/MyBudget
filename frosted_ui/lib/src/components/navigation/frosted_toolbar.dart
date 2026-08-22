import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../primitives/frosted_glass.dart';
import '../../primitives/frosted_glass_level.dart';
import '../actions/_interactive_surface.dart';

const double _kToolbarHeight = 48;

/// A desktop chrome toolbar in Liquid Glass.
///
/// Hosts breadcrumb-style navigation on the left, a search shortcut in the
/// middle, and arbitrary trailing actions.
class FrostedToolbar extends StatelessWidget {
  const FrostedToolbar({
    this.breadcrumbs = const <String>[],
    this.onBreadcrumbTap,
    this.onSearchTap,
    this.searchHint = 'Search or jump to...',
    this.searchShortcut = '⌘K',
    this.actions = const <Widget>[],
    this.level = FrostedGlassLevel.regular,
    this.tone = FrostedGlassTone.auto,
    super.key,
  });

  final List<String> breadcrumbs;
  final ValueChanged<int>? onBreadcrumbTap;
  final VoidCallback? onSearchTap;
  final String searchHint;
  final String searchShortcut;
  final List<Widget> actions;
  final FrostedGlassLevel level;
  final FrostedGlassTone tone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(FrostedSpacing.sp3),
        child: FrostedGlass(
          level: level,
          tone: tone,
          borderRadius: BorderRadius.circular(FrostedRadius.lg),
          padding: const EdgeInsets.symmetric(horizontal: FrostedSpacing.sp3),
          child: SizedBox(
            height: _kToolbarHeight,
            child: Row(
              children: <Widget>[
                _Breadcrumbs(crumbs: breadcrumbs, onTap: onBreadcrumbTap),
                const Spacer(),
                if (onSearchTap != null)
                  _SearchButton(
                    hint: searchHint,
                    shortcut: searchShortcut,
                    onTap: onSearchTap!,
                  ),
                for (final Widget action in actions) ...<Widget>[
                  const SizedBox(width: FrostedSpacing.sp2),
                  action,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({required this.crumbs, required this.onTap});

  final List<String> crumbs;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (int i = 0; i < crumbs.length; i++) ...<Widget>[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FrostedSpacing.sp1,
              ),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
            ),
          _Crumb(
            label: crumbs[i],
            active: i == crumbs.length - 1,
            onTap: onTap == null ? null : () => onTap!(i),
          ),
        ],
      ],
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextStyle style = FrostedTypeScale.labelLarge.copyWith(
      color: active ? cs.onSurface : cs.onSurfaceVariant,
      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
    );

    if (onTap == null || active) {
      return Text(label, style: style);
    }
    return InteractiveSurface(
      onTap: onTap,
      semanticsLabel: label,
      builder: (BuildContext context, InteractionStates s) => s.ink(
        color: cs.onSurface,
        borderRadius: BorderRadius.circular(FrostedRadius.xs),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FrostedSpacing.sp1,
            vertical: 2,
          ),
          child: Text(label, style: style),
        ),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({
    required this.hint,
    required this.shortcut,
    required this.onTap,
  });

  final String hint;
  final String shortcut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return InteractiveSurface(
      onTap: onTap,
      semanticsLabel: hint,
      builder: (BuildContext context, InteractionStates s) => DecoratedBox(
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(FrostedRadius.md),
        ),
        child: s.ink(
          color: cs.onSurface,
          borderRadius: BorderRadius.circular(FrostedRadius.md),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FrostedSpacing.sp3,
              vertical: FrostedSpacing.sp2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.search, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: FrostedSpacing.sp2),
                Text(
                  hint,
                  style: FrostedTypeScale.labelMedium.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: FrostedSpacing.sp3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FrostedSpacing.sp1 + 2,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(FrostedRadius.xs),
                  ),
                  child: Text(
                    shortcut,
                    style: FrostedTypeScale.labelSmall.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
