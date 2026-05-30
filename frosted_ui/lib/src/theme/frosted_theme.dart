import 'package:flutter/material.dart';

import 'frosted_glass_tokens.dart';
import 'frosted_motion_tokens.dart';
import 'frosted_state_tokens.dart';
import 'frosted_text_theme.dart';
import 'frosted_tokens.dart';

/// Entry-point for consuming Frosted UI in a Flutter app.
///
/// Pass the produced [ThemeData] to `MaterialApp.theme` / `darkTheme`. The
/// app's seed color drives every color in the system via M3 dynamic color —
/// the library never decides colors of its own.
class FrostedTheme {
  const FrostedTheme._();

  /// Build a light [ThemeData] derived from [seedColor].
  static ThemeData light({required Color seedColor}) {
    return _build(seedColor: seedColor, brightness: Brightness.light);
  }

  /// Build a dark [ThemeData] derived from [seedColor]. Dark is the default
  /// target for Glass Expressive — glass material reads best on dark.
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

    final FrostedStateTokens state =
        isDark ? FrostedStateTokens.dark() : FrostedStateTokens.light();
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
