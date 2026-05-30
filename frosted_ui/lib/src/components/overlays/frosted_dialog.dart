import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_tokens.dart';
import 'frosted_scrim.dart';

/// Shows a [FrostedDialog] as a modal route — a glass shell wrapping an opaque
/// M3 interior, over a scrim. Returns the value the dialog pops with.
Future<T?> showFrostedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final ThemeData theme = Theme.of(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
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
            onDismiss: barrierDismissible
                ? () => Navigator.of(context).maybePop()
                : null,
          ),
          FadeTransition(
            opacity: curve,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(curve),
              child: child,
            ),
          ),
        ],
      );
    },
  );
}

/// A modal dialog: a Liquid Glass shell around an opaque M3 interior, with a
/// title, body, and a trailing row of actions.
///
/// Present it through [showFrostedDialog].
class FrostedDialog extends StatelessWidget {
  const FrostedDialog({
    required this.title,
    this.body,
    this.actions = const <Widget>[],
    super.key,
  });

  final String title;
  final Widget? body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FrostedSpacing.sp6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surfaceContainer.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(FrostedRadius.xl),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: context.frostedTokens.glass.liftedShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(FrostedSpacing.sp5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: FrostedTypeScale.titleLarge
                        .copyWith(color: cs.onSurface),
                  ),
                  if (body != null) ...<Widget>[
                    const SizedBox(height: FrostedSpacing.sp3),
                    DefaultTextStyle.merge(
                      style: FrostedTypeScale.bodyMedium
                          .copyWith(color: cs.onSurfaceVariant),
                      child: body!,
                    ),
                  ],
                  if (actions.isNotEmpty) ...<Widget>[
                    const SizedBox(height: FrostedSpacing.sp5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        for (int i = 0; i < actions.length; i++) ...<Widget>[
                          if (i > 0) const SizedBox(width: FrostedSpacing.sp2),
                          actions[i],
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
