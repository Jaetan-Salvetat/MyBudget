import 'package:flutter/material.dart';

import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '../actions/_interactive_surface.dart';

/// Visual variants of [FrostedTabs].
enum FrostedTabsVariant {
  /// Equal-width tabs spanning the row. The active indicator hugs the label
  /// width and is centered under it (M3 Expressive primary tabs).
  primary,

  /// Compact, scrollable tabs anchored to the leading edge. The active
  /// indicator spans the full tab width (M3 secondary tabs).
  secondary,
}

/// A single [FrostedTabs] destination.
class FrostedTab {
  const FrostedTab({required this.label, this.icon});

  final String label;
  final IconData? icon;
}

/// In-page content tabs with a single underline indicator that springs
/// between destinations.
///
/// Opaque M3 surface — never glass. Pair with a [PageView] or [IndexedStack]
/// in the body to switch the actual content.
class FrostedTabs extends StatelessWidget {
  const FrostedTabs({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    this.variant = FrostedTabsVariant.primary,
    super.key,
  });

  final List<FrostedTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final FrostedTabsVariant variant;

  static const double _height = 48;
  static const double _indicatorHeight = 3;
  static const double _indicatorRadius = 3;
  static const double _iconSize = 24;
  static const double _hPad = FrostedSpacing.sp4;

  double _contentWidth(FrostedTab tab, TextScaler scaler) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: tab.label, style: FrostedTypeScale.labelLarge),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    double width = painter.width;
    if (tab.icon != null) width += _iconSize + FrostedSpacing.sp2;
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion slide = context.frostedTokens.motion.fluid;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final bool isPrimary = variant == FrostedTabsVariant.primary;

    final List<double> contentWidths = <double>[
      for (final FrostedTab tab in tabs) _contentWidth(tab, scaler),
    ];

    if (isPrimary) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double tabWidth = constraints.maxWidth / tabs.length;
          final double left =
              tabWidth * currentIndex + (tabWidth - contentWidths[currentIndex]) / 2;
          return _Stack(
            width: constraints.maxWidth,
            indicatorLeft: left,
            indicatorWidth: contentWidths[currentIndex],
            slide: slide,
            divider: cs.outlineVariant,
            indicatorColor: cs.primary,
            row: Row(
              children: <Widget>[
                for (int i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _Tab(
                      tab: tabs[i],
                      selected: i == currentIndex,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    double offset = 0;
    final List<double> lefts = <double>[];
    for (int i = 0; i < tabs.length; i++) {
      lefts.add(offset + _hPad);
      offset += contentWidths[i] + _hPad * 2;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: _Stack(
        width: offset,
        indicatorLeft: lefts[currentIndex],
        indicatorWidth: contentWidths[currentIndex],
        slide: slide,
        divider: cs.outlineVariant,
        indicatorColor: cs.primary,
        row: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < tabs.length; i++)
              _Tab(
                tab: tabs[i],
                selected: i == currentIndex,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stack extends StatelessWidget {
  const _Stack({
    required this.width,
    required this.indicatorLeft,
    required this.indicatorWidth,
    required this.slide,
    required this.divider,
    required this.indicatorColor,
    required this.row,
  });

  final double width;
  final double indicatorLeft;
  final double indicatorWidth;
  final FrostedMotion slide;
  final Color divider;
  final Color indicatorColor;
  final Widget row;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: FrostedTabs._height,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(height: 1, color: divider),
          ),
          Positioned.fill(child: row),
          AnimatedPositioned(
            duration: slide.duration,
            curve: slide.curve,
            left: indicatorLeft,
            width: indicatorWidth,
            bottom: 0,
            height: FrostedTabs._indicatorHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(FrostedTabs._indicatorRadius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final FrostedTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;

    return InteractiveSurface(
      onTap: onTap,
      semanticsLabel: tab.label,
      semanticsSelected: selected,
      builder: (BuildContext context, InteractionStates s) {
        final Color target = _resolveFg(cs, s);
        return TweenAnimationBuilder<Color?>(
          duration: motion.duration,
          curve: motion.curve,
          tween: ColorTween(end: target),
          builder: (BuildContext context, Color? color, Widget? _) {
            final Color fg = color ?? target;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: FrostedTabs._hPad),
              child: Center(
                widthFactor: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (tab.icon != null) ...<Widget>[
                      Icon(tab.icon, size: FrostedTabs._iconSize, color: fg),
                      const SizedBox(width: FrostedSpacing.sp2),
                    ],
                    Text(
                      tab.label,
                      style: FrostedTypeScale.labelLarge.copyWith(color: fg),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _resolveFg(ColorScheme cs, InteractionStates s) {
    if (selected) return cs.primary;
    if (s.pressed || s.focused || s.hovered) return cs.primary;
    return cs.onSurfaceVariant;
  }
}
