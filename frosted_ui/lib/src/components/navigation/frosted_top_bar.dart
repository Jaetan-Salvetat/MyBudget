import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_spacing.dart';
import '../../primitives/frosted_glass.dart';
import '../../primitives/frosted_glass_level.dart';

const double _kToolbarHeight = 56;

class FrostedTopBar extends StatelessWidget implements PreferredSizeWidget {
  const FrostedTopBar({
    required this.title,
    this.leading,
    this.actions = const <Widget>[],
    this.toolbarHeight = _kToolbarHeight,
    super.key,
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final double toolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  static double bodyTopPadding(
    BuildContext context, {
    double toolbarHeight = _kToolbarHeight,
  }) {
    return MediaQuery.of(context).padding.top + toolbarHeight;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final double topInset = MediaQuery.of(context).padding.top;

    return FrostedGlass(
      level: FrostedGlassLevel.thick,
      tone: FrostedGlassTone.auto,
      elevation: FrostedGlassElevation.none,
      borderRadius: BorderRadius.zero,
      borderEdges: const <FrostedGlassEdge>{FrostedGlassEdge.bottom},
      padding: EdgeInsets.only(top: topInset),
      child: SizedBox(
        height: toolbarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FrostedSpacing.sp1),
          child: Row(
            children: <Widget>[
              leading ?? const SizedBox(width: 44),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: FrostedSpacing.sp2),
                  child: Text(
                    title,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              ...actions,
              if (actions.isEmpty) const SizedBox(width: 44),
            ],
          ),
        ),
      ),
    );
  }
}
