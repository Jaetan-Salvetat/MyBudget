import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_shape.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../primitives/frosted_glass.dart';
import '../../primitives/frosted_glass_level.dart';
import '../actions/frosted_icon_button.dart';

const AnimationStyle _kSheetAnimation = AnimationStyle(
  duration: Duration(milliseconds: 260),
  reverseDuration: Duration(milliseconds: 220),
  curve: Cubic(0.32, 0.72, 0, 1),
  reverseCurve: Cubic(0.32, 0.72, 0, 1),
);

const double _kStatusBarGap = FrostedSpacing.sp2;

Future<T?> showFrostedBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push<T>(
    _FrostedBottomSheetRoute<T>(
      builder: (BuildContext sheetContext) => Padding(
        padding: const EdgeInsets.only(top: _kStatusBarGap),
        child: builder(sheetContext),
      ),
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
    ),
  );
}

class _FrostedBottomSheetRoute<T> extends ModalBottomSheetRoute<T> {
  _FrostedBottomSheetRoute({
    required super.builder,
    required super.capturedThemes,
    required super.barrierLabel,
    required super.isDismissible,
    required super.enableDrag,
  }) : super(
         isScrollControlled: true,
         backgroundColor: Colors.transparent,
         elevation: 0,
         modalBarrierColor: Colors.transparent,
         useSafeArea: true,
         sheetAnimationStyle: _kSheetAnimation,
       );

  @override
  Widget buildModalBarrier() {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        IgnorePointer(
          child: FrostedGlass(
            level: FrostedGlassLevel.thin,
            tone: FrostedGlassTone.dark,
            elevation: FrostedGlassElevation.none,
            borderRadius: BorderRadius.zero,
            animation: animation,
          ),
        ),
        super.buildModalBarrier(),
      ],
    );
  }
}

class FrostedBottomSheet extends StatelessWidget {
  const FrostedBottomSheet({required this.child, this.title, super.key});

  final Widget child;

  final String? title;

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
                if (title != null) ...<Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          title!,
                          style: FrostedTypeScale.titleLarge.copyWith(
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: FrostedSpacing.sp2),
                      FrostedIconButton.standard(
                        icon: Icons.close,
                        shape: FrostedShape.pill,
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: FrostedSpacing.sp3),
                ],
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
