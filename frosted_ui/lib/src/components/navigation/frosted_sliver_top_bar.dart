import 'package:flutter/material.dart';

import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../primitives/frosted_glass.dart';
import '../../primitives/frosted_glass_level.dart';

const double _kCompactHeight = 56;
const double _kDefaultLargeHeight = 56;

/// A collapsible top app bar in Liquid Glass, designed for use inside a
/// `CustomScrollView`.
///
/// The bar starts expanded — a 56dp action row above a [largeTitleHeight]
/// area reserved for the large title — and shrinks down to just the action
/// row as the user scrolls. Pin it to the top via [SliverPersistentHeader].
///
/// Place it as the first sliver of a `CustomScrollView`:
/// ```dart
/// CustomScrollView(
///   slivers: <Widget>[
///     FrostedSliverTopBar(title: 'Library'),
///     SliverList(...),
///   ],
/// )
/// ```
class FrostedSliverTopBar extends StatelessWidget {
  const FrostedSliverTopBar({
    required this.title,
    this.leading,
    this.actions = const <Widget>[],
    this.largeTitleHeight = _kDefaultLargeHeight,
    super.key,
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final double largeTitleHeight;

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _Delegate(
        topInset: topInset,
        title: title,
        leading: leading,
        actions: actions,
        largeTitleHeight: largeTitleHeight,
      ),
    );
  }
}

class _Delegate extends SliverPersistentHeaderDelegate {
  _Delegate({
    required this.topInset,
    required this.title,
    required this.leading,
    required this.actions,
    required this.largeTitleHeight,
  });

  final double topInset;
  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final double largeTitleHeight;

  @override
  double get maxExtent => topInset + _kCompactHeight + largeTitleHeight;

  @override
  double get minExtent => topInset + _kCompactHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double range = maxExtent - minExtent;
    final double progress =
        range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final TextTheme text = Theme.of(context).textTheme;

    return FrostedGlass(
      level: FrostedGlassLevel.thick,
      tone: FrostedGlassTone.auto,
      elevation: FrostedGlassElevation.none,
      borderRadius: BorderRadius.zero,
      borderEdges: const <FrostedGlassEdge>{FrostedGlassEdge.bottom},
      padding: EdgeInsets.only(top: topInset),
      child: SizedBox(
        height: maxExtent - topInset - shrinkOffset.clamp(0.0, range),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: _kCompactHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FrostedSpacing.sp1,
                ),
                child: Row(
                  children: <Widget>[
                    leading ?? const SizedBox(width: 44),
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: FrostedSpacing.sp2),
                        child: Opacity(
                          opacity: progress,
                          child: Text(
                            title,
                            style: text.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    ...actions,
                    if (actions.isEmpty) const SizedBox(width: 44),
                  ],
                ),
              ),
            ),
            if (progress < 1.0)
              SizedBox(
                height:
                    (largeTitleHeight - shrinkOffset).clamp(0.0, largeTitleHeight),
                child: ClipRect(
                  child: OverflowBox(
                    minHeight: 0,
                    maxHeight: largeTitleHeight,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      height: largeTitleHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FrostedSpacing.sp3,
                          vertical: FrostedSpacing.sp1,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Opacity(
                            opacity: 1 - progress,
                            child: Text(
                              title,
                              style: FrostedTypeScale.displaySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _Delegate old) {
    return old.topInset != topInset ||
        old.title != title ||
        old.leading != leading ||
        old.actions != actions ||
        old.largeTitleHeight != largeTitleHeight;
  }
}
