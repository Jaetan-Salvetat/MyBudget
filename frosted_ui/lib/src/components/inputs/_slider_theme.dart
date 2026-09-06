import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_slider_tokens.dart';
import '../../foundations/frosted_type_scale.dart';

const double _draggedOverlayOpacity = 0.1;
const double _hoveredOverlayOpacity = 0.08;
const double _focusedOverlayOpacity = 0.1;
const double _secondaryTrackOpacity = 0.54;

SliderThemeData frostedSliderTheme(ColorScheme cs) {
  return SliderThemeData(
    trackHeight: FrostedSliderTokens.trackHeight,
    trackGap: FrostedSliderTokens.handleGap,
    activeTrackColor: cs.primary,
    inactiveTrackColor: cs.secondaryContainer,
    secondaryActiveTrackColor: cs.primary.withValues(
      alpha: _secondaryTrackOpacity,
    ),
    disabledActiveTrackColor: cs.onSurface.withValues(
      alpha: FrostedSliderTokens.disabledActiveOpacity,
    ),
    disabledInactiveTrackColor: cs.onSurface.withValues(
      alpha: FrostedSliderTokens.disabledInactiveOpacity,
    ),
    disabledSecondaryActiveTrackColor: cs.onSurface.withValues(
      alpha: FrostedSliderTokens.disabledActiveOpacity,
    ),
    activeTickMarkColor: cs.onPrimary,
    inactiveTickMarkColor: cs.onSecondaryContainer,
    disabledActiveTickMarkColor: cs.onInverseSurface,
    disabledInactiveTickMarkColor: cs.onSurface,
    thumbColor: cs.primary,
    disabledThumbColor: cs.onSurface.withValues(
      alpha: FrostedSliderTokens.disabledActiveOpacity,
    ),
    overlayColor: WidgetStateColor.resolveWith(
      (Set<WidgetState> states) => switch (states) {
        final Set<WidgetState> s when s.contains(WidgetState.dragged) =>
          cs.primary.withValues(alpha: _draggedOverlayOpacity),
        final Set<WidgetState> s when s.contains(WidgetState.hovered) =>
          cs.primary.withValues(alpha: _hoveredOverlayOpacity),
        final Set<WidgetState> s when s.contains(WidgetState.focused) =>
          cs.primary.withValues(alpha: _focusedOverlayOpacity),
        _ => Colors.transparent,
      },
    ),
    thumbSize: WidgetStateProperty.resolveWith(
      (Set<WidgetState> states) =>
          states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused)
          ? const Size(
              FrostedSliderTokens.pressedHandleWidth,
              FrostedSliderTokens.handleHeight,
            )
          : const Size(
              FrostedSliderTokens.handleWidth,
              FrostedSliderTokens.handleHeight,
            ),
    ),
    overlayShape: const RoundSliderOverlayShape(),
    valueIndicatorColor: cs.inverseSurface,
    valueIndicatorTextStyle: FrostedTypeScale.labelLarge.copyWith(
      color: cs.onInverseSurface,
    ),
    showValueIndicator: ShowValueIndicator.onDrag,
  );
}
