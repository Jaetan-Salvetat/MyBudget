import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../theme/frosted_tokens.dart';
import 'frosted_scrim.dart';

/// Shows a [FrostedBottomSheet] as a modal route — a glass sheet that slides
/// up from the bottom edge over a scrim. Returns the value it pops with.
Future<T?> showFrostedBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  final ThemeData theme = Theme.of(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (BuildContext context, Animation<double> _,
            Animation<double> _) =>
        Theme(data: theme, child: builder(context)),
    transitionBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondary,
      Widget child,
    ) {
      final CurvedAnimation curve = CurvedAnimation(
        parent: animation,
        curve: const Cubic(0.32, 0.72, 0, 1),
      );
      return Stack(
        children: <Widget>[
          FrostedScrim(
            animation: curve,
            onDismiss: isDismissible
                ? () => Navigator.of(context).maybePop()
                : null,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            ),
          ),
        ],
      );
    },
  );
}

/// A bottom sheet: a Liquid Glass surface anchored to the bottom edge, with a
/// drag handle and a top concentric corner radius.
///
/// Present it through [showFrostedBottomSheet].
class FrostedBottomSheet extends StatelessWidget {
  const FrostedBottomSheet({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);
    final double bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

    const BorderRadius radius = BorderRadius.vertical(
      top: Radius.circular(FrostedRadius.xxl),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainer.withValues(alpha: 0.72),
          borderRadius: radius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: context.frostedTokens.glass.liftedShadow,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            FrostedSpacing.sp4,
            FrostedSpacing.sp2,
            FrostedSpacing.sp4,
            FrostedSpacing.sp4 + bottomSafe,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: FrostedSpacing.sp3),
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(FrostedRadius.full),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
        ),
      ),
    );
  }
}
