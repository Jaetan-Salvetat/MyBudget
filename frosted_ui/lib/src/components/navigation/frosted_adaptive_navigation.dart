import 'package:flutter/material.dart';

import '../../foundations/frosted_breakpoints.dart';
import 'frosted_nav_item.dart';
import 'frosted_navigation_rail.dart';
import 'frosted_scaffold.dart';
import 'frosted_sidebar.dart';
import 'frosted_bottom_bar.dart';

/// A complete adaptive screen layout that picks the right navigation
/// component for the current window size:
///
/// | Width            | Navigation                                  |
/// |------------------|---------------------------------------------|
/// | < 600            | [FrostedBottomBar] at the bottom               |
/// | 600 – 839        | Collapsed [FrostedNavigationRail] on the    |
/// |                  | leading side                                |
/// | 840 – 1239       | Extended [FrostedNavigationRail] leading    |
/// | ≥ 1240           | [sidebar] when provided, else extended rail |
///
/// Place this widget at the root of a route — it builds the [FrostedScaffold]
/// itself, so don't wrap it in another Scaffold.
class FrostedAdaptiveNavigation extends StatelessWidget {
  const FrostedAdaptiveNavigation({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.body,
    this.sidebar,
    this.appBar,
    super.key,
  });

  final List<FrostedNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget body;
  final FrostedSidebar? sidebar;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;

        if (width < FrostedBreakpoints.compact) {
          return FrostedScaffold(
            appBar: appBar,
            body: body,
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: FrostedBottomBar(
                  items: items,
                  currentIndex: currentIndex,
                  onTap: onTap,
                ),
              ),
            ),
          );
        }

        final Widget leading = width >= FrostedBreakpoints.expanded &&
                sidebar != null
            ? sidebar!
            : FrostedNavigationRail(
                items: items,
                currentIndex: currentIndex,
                onTap: onTap,
                extended: width >= FrostedBreakpoints.medium,
              );

        return FrostedScaffold(
          appBar: appBar,
          body: Row(
            children: <Widget>[
              leading,
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}
