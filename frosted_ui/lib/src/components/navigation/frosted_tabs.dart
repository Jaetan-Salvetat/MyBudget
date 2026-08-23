import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '../actions/_interactive_surface.dart';

/// Visual variants of [FrostedTabs].
enum FrostedTabsVariant {
  /// Equal-width tabs spanning the row. The active indicator hugs the label
  /// width and is centered under it (M3 Expressive primary tabs). Falls back
  /// to a leading-anchored scrollable row when the labels cannot fit.
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
class FrostedTabs extends StatefulWidget {
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

  @override
  State<FrostedTabs> createState() => _FrostedTabsState();
}

class _FrostedTabsState extends State<FrostedTabs> {
  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(FrostedTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex == oldWidget.currentIndex) return;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) _revealSelected();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double _contentWidth(FrostedTab tab, TextScaler scaler) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: tab.label, style: FrostedTypeScale.labelLarge),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    double width = painter.width;
    if (tab.icon != null) {
      width += FrostedTabs._iconSize + FrostedSpacing.sp2;
    }
    return width;
  }

  List<double> _contentWidths(TextScaler scaler) => <double>[
    for (final FrostedTab tab in widget.tabs) _contentWidth(tab, scaler),
  ];

  /// Leading edge of every tab in the scrollable row. A tab box is its content
  /// plus the horizontal padding on both sides.
  List<double> _tabLefts(List<double> contentWidths) {
    final List<double> lefts = <double>[];
    double offset = 0;
    for (final double content in contentWidths) {
      lefts.add(offset);
      offset += content + FrostedTabs._hPad * 2;
    }
    return lefts;
  }

  /// Brings the selected tab back inside the viewport when the selection comes
  /// from outside the row — a swipe on the paired page view, a deep link.
  void _revealSelected() {
    if (!_scroll.hasClients) return;
    final List<double> contentWidths = _contentWidths(
      MediaQuery.textScalerOf(context),
    );
    final int index = widget.currentIndex;
    if (index < 0 || index >= contentWidths.length) return;

    final double left = _tabLefts(contentWidths)[index];
    final double right = left + contentWidths[index] + FrostedTabs._hPad * 2;
    final ScrollPosition position = _scroll.position;

    double target = position.pixels;
    if (right > position.pixels + position.viewportDimension) {
      target = right - position.viewportDimension;
    }
    if (left < target) target = left;
    target = target.clamp(position.minScrollExtent, position.maxScrollExtent);
    if (target == position.pixels) return;

    final FrostedMotion motion = context.frostedTokens.motion.fluid;
    _scroll.animateTo(target, duration: motion.duration, curve: motion.curve);
  }

  Widget _row({required bool expandTabs}) {
    return Row(
      mainAxisSize: expandTabs ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < widget.tabs.length; i++)
          if (expandTabs) Expanded(child: _tabAt(i)) else _tabAt(i),
      ],
    );
  }

  Widget _tabAt(int index) => _Tab(
    tab: widget.tabs[index],
    selected: index == widget.currentIndex,
    onTap: () => widget.onTap(index),
  );

  /// Leading-anchored, horizontally scrollable row — used by the secondary
  /// variant, and by the primary variant when equal-width cells would be too
  /// narrow to hold their content.
  Widget _scrollableRow({
    required List<double> contentWidths,
    required ColorScheme cs,
    required FrostedMotion slide,
    required bool indicatorSpansTab,
  }) {
    final List<double> lefts = _tabLefts(contentWidths);
    final double selected = contentWidths[widget.currentIndex];
    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      child: _Stack(
        width: lefts.last + contentWidths.last + FrostedTabs._hPad * 2,
        indicatorLeft: indicatorSpansTab
            ? lefts[widget.currentIndex]
            : lefts[widget.currentIndex] + FrostedTabs._hPad,
        indicatorWidth: indicatorSpansTab
            ? selected + FrostedTabs._hPad * 2
            : selected,
        slide: slide,
        divider: cs.outlineVariant,
        indicatorColor: cs.primary,
        row: _row(expandTabs: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion slide = context.frostedTokens.motion.fluid;
    final List<double> contentWidths = _contentWidths(
      MediaQuery.textScalerOf(context),
    );

    if (widget.variant == FrostedTabsVariant.secondary) {
      return _scrollableRow(
        contentWidths: contentWidths,
        cs: cs,
        slide: slide,
        indicatorSpansTab: true,
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double required =
            contentWidths.fold<double>(0, _sum) +
            widget.tabs.length * FrostedTabs._hPad * 2;
        if (required > constraints.maxWidth) {
          return _scrollableRow(
            contentWidths: contentWidths,
            cs: cs,
            slide: slide,
            indicatorSpansTab: false,
          );
        }

        final double cellWidth = constraints.maxWidth / widget.tabs.length;
        final double indicatorWidth = contentWidths[widget.currentIndex];
        return _Stack(
          width: constraints.maxWidth,
          indicatorLeft:
              cellWidth * widget.currentIndex +
              (cellWidth - indicatorWidth) / 2,
          indicatorWidth: indicatorWidth,
          slide: slide,
          divider: cs.outlineVariant,
          indicatorColor: cs.primary,
          row: _row(expandTabs: true),
        );
      },
    );
  }

  static double _sum(double total, double value) => total + value;
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
  const _Tab({required this.tab, required this.selected, required this.onTap});

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
            return s.ink(
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FrostedTabs._hPad,
                ),
                child: Center(
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
                      ),
                    ],
                  ),
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
