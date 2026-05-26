import 'package:flutter/material.dart';

import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';

/// Visual variants of [FrostedTabs].
enum FrostedTabsVariant {
  /// Equal-width tabs spanning the available row.
  primary,

  /// Compact, scrollable tabs anchored to the leading edge.
  secondary,
}

/// In-page content tabs with an underline indicator.
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

  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final FrostedTabsVariant variant;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;
    final bool isPrimary = variant == FrostedTabsVariant.primary;

    final Widget row = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double? itemWidth = isPrimary && constraints.hasBoundedWidth
            ? constraints.maxWidth / tabs.length
            : null;
        return Stack(
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < tabs.length; i++)
                  _Tab(
                    label: tabs[i],
                    selected: i == currentIndex,
                    width: itemWidth,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
            if (itemWidth != null)
              AnimatedPositioned(
                duration: motion.duration,
                curve: motion.curve,
                left: itemWidth * currentIndex,
                bottom: 0,
                width: itemWidth,
                height: 3,
                child: _Indicator(color: cs.primary),
              )
            else
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _ScrollableIndicator(
                  count: tabs.length,
                  currentIndex: currentIndex,
                  color: cs.primary,
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                color: cs.outlineVariant,
              ),
            ),
          ],
        );
      },
    );

    if (isPrimary) return row;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: row,
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double? width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color fg = selected ? cs.primary : cs.onSurfaceVariant;

    final Widget inner = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FrostedSpacing.sp4,
        vertical: FrostedSpacing.sp3,
      ),
      child: Text(
        label,
        style: FrostedTypeScale.labelLarge.copyWith(
          color: fg,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return InkWell(
      onTap: onTap,
      child: width == null
          ? inner
          : SizedBox(
              width: width,
              child: Center(child: inner),
            ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
      ),
    );
  }
}

class _ScrollableIndicator extends StatelessWidget {
  const _ScrollableIndicator({
    required this.count,
    required this.currentIndex,
    required this.color,
  });

  final int count;
  final int currentIndex;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < count; i++)
          Expanded(
            child: Container(
              height: 3,
              color: i == currentIndex ? color : Colors.transparent,
            ),
          ),
      ],
    );
  }
}
