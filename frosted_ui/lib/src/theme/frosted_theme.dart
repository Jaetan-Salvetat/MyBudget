import 'package:material_ui/material_ui.dart';

import 'frosted_glass_tokens.dart';
import 'frosted_motion_tokens.dart';
import 'frosted_state_tokens.dart';
import 'frosted_text_theme.dart';
import 'frosted_tokens.dart';

class FrostedTheme {
  const FrostedTheme._();

  static ThemeData light({required Color seedColor}) {
    return _build(seedColor: seedColor, brightness: Brightness.light);
  }

  static ThemeData dark({required Color seedColor}) {
    return _build(seedColor: seedColor, brightness: Brightness.dark);
  }

  static ThemeData _build({
    required Color seedColor,
    required Brightness brightness,
  }) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final bool isDark = brightness == Brightness.dark;

    final FrostedStateTokens state = isDark
        ? FrostedStateTokens.dark()
        : FrostedStateTokens.light();
    final FrostedTokens tokens = FrostedTokens(
      glass: FrostedGlassTokens.standard(),
      motion: FrostedMotionTokens.standard(),
      state: state,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: buildFrostedTextTheme().apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      splashFactory: InkSparkle.splashFactory,
      splashColor: state.press,
      highlightColor: state.hover,
      hoverColor: state.hover,
      focusColor: state.focus,
      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }
}
