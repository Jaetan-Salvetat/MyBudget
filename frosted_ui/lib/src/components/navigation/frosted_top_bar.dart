import 'package:flutter/material.dart';

import '../../foundations/frosted_spacing.dart';
import '../../primitives/frosted_glass.dart';
import '../../primitives/frosted_glass_level.dart';

const double _kToolbarHeight = 56;

/// An edge-to-edge top app bar in Liquid Glass.
///
/// Spans the full width of the surrounding [Scaffold], attaches to the top
/// edge, and gives back a rounded-bottom silhouette. The status-bar inset is
/// handled internally, so [preferredSize] only advertises the [toolbarHeight]
/// — pair the [FrostedScaffold]'s default `extendBodyBehindAppBar: true` with
/// [bodyTopPadding] to lay out the body below the bar.
///
/// The glass material is fixed (`regular` level, auto tone, no shadow) and is
/// not customizable.
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

  /// Top padding the body should reserve so its first item clears the bar.
  ///
  /// Use it in the body's `padding`:
  /// ```dart
  /// padding: EdgeInsets.only(top: FrostedTopBar.bodyTopPadding(context))
  /// ```
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
      level: FrostedGlassLevel.ultraThick,
      tone: FrostedGlassTone.auto,
      elevation: FrostedGlassElevation.none,
      borderRadius: BorderRadius.zero,
      padding: EdgeInsets.only(top: topInset),
      child: SizedBox(
        height: toolbarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FrostedSpacing.sp1,
          ),
          child: Row(
            children: <Widget>[
              leading ?? const SizedBox(width: 44),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: FrostedSpacing.sp2),
                  child: Text(
                    title,
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
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
