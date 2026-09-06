import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_breakpoints.dart';
import 'frosted_nav_item.dart';
import 'frosted_navigation_rail.dart';
import 'frosted_scaffold.dart';
import 'frosted_sidebar.dart';
import 'frosted_nav_pill.dart';

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
                child: FrostedNavPill(
                  destinations: items,
                  selectedIndex: currentIndex,
                  onDestinationSelected: onTap,
                ),
              ),
            ),
          );
        }

        final Widget leading =
            width >= FrostedBreakpoints.expanded && sidebar != null
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
