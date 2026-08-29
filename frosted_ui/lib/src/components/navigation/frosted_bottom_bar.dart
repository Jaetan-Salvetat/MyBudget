import 'package:material_ui/material_ui.dart';

import '../../primitives/frosted_glass.dart';
import '../../primitives/frosted_glass_level.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import 'frosted_badge.dart';
import 'frosted_nav_item.dart';

/// An edge-to-edge bottom navigation bar in Liquid Glass.
///
/// It *is* the Material 3 [NavigationBar] : same height, same 64x32 stadium
/// indicator, same label padding, same 500 ms selection animation, same ink
/// bounded to the indicator. Frosted replaces one thing — the surface. Where
/// M3 paints `surfaceContainer`, this paints glass, so the body running behind
/// the bar keeps showing through it. Re-cutting those tokens by hand buys
/// nothing and drifts the day Material moves them.
///
/// The counterpart of [FrostedTopBar], and its opposite in intent to
/// [FrostedNavPill] : the pill hugs its content and floats over the page as a
/// free-standing object, this bar spans the screen and attaches to its bottom
/// edge. Of two chromes on that edge, the one that floats is the one that
/// carries the action — the bar only says where you are.
///
/// It sits on [FrostedGlassLevel.regular], the level the scale reserves for
/// tab bars: a denser veil turns the content passing underneath into a grey
/// slab instead of blurred matter.
///
/// The bar owns the bottom safe-area inset, as [NavigationBar] always has: it
/// is the last thing on the screen, so there is no second placement where the
/// inset would not apply.
///
/// [folded] rolls the bar away — what a keyboard asks for, since it buries the
/// destinations and leaves only the thing being typed into. It folds by height
/// rather than by fading: a backdrop blur inside an opacity layer stops
/// sampling and turns grey. Folding rather than removing the bar keeps
/// whatever floats above it resting on an edge that never jumps.
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

  /// Handed to [NavigationBar.labelBehavior]. Null keeps the M3 default.
  final NavigationDestinationLabelBehavior? labelBehavior;

  /// Handed to [NavigationBar.height]. Null keeps the M3 token.
  final double? height;

  /// Whether the bar is rolled away, leaving the edge to whatever floats on it.
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
            // The glass is the surface : anything M3 would paint here would
            // sit on top of it and put the material out.
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

  /// The destination's glyph, and the badge it may carry. Left to the ambient
  /// [IconTheme], which is where [NavigationBar] puts the M3 icon size and the
  /// colour of the state the destination is in.
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
