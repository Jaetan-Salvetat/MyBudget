import 'package:material_ui/material_ui.dart';

import '../../primitives/frosted_glass.dart';
import '../../primitives/frosted_glass_level.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import 'frosted_badge.dart';
import 'frosted_nav_item.dart';

class FrostedBottomBar extends StatelessWidget {
  const FrostedBottomBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.labelBehavior,
    this.height,
    this.folded = false,
    super.key,
  });

  final List<FrostedNavItem> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  final NavigationDestinationLabelBehavior? labelBehavior;

  final double? height;

  final bool folded;

  @override
  Widget build(BuildContext context) {
    final FrostedMotion motion = context.frostedTokens.motion.snappy;

    return FrostedGlass(
      level: FrostedGlassLevel.regular,
      tone: FrostedGlassTone.auto,
      elevation: FrostedGlassElevation.none,
      borderRadius: BorderRadius.zero,
      borderEdges: const <FrostedGlassEdge>{FrostedGlassEdge.top},
      child: ClipRect(
        child: AnimatedAlign(
          alignment: Alignment.topCenter,
          heightFactor: folded ? 0 : 1,
          duration: motion.duration,
          curve: motion.curve,
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelBehavior: labelBehavior,
            height: height,
            backgroundColor: Colors.transparent,
            elevation: 0,
            destinations: <Widget>[
              for (final FrostedNavItem item in destinations)
                NavigationDestination(
                  icon: _glyph(item, item.icon),
                  selectedIcon: item.selectedIcon == null
                      ? null
                      : _glyph(item, item.selectedIcon!),
                  label: item.label,
                  tooltip: item.tooltip,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glyph(FrostedNavItem item, IconData icon) {
    final Widget glyph = Icon(icon);
    final FrostedBadge? badge = item.badge;
    if (badge == null) return glyph;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        glyph,
        Positioned(top: -2, right: -8, child: FrostedBadgeView(badge: badge)),
      ],
    );
  }
}
