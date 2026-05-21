import 'package:flutter/material.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';

class AppTheme {
  AppTheme._();

  static const Color _seedColor = Color(0xFF2A55D3);
  static const Color _secondaryColor = Color(0xFF6750A4);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    ).copyWith(secondary: _secondaryColor);

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: AppTextStyles.buildTextTheme(brightness),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: scheme.onSurface,
        unselectedItemColor: scheme.onSurface,
      ),
      extensions: <ThemeExtension<dynamic>>[
        brightness == Brightness.dark
            ? FinanceColors.dark
            : FinanceColors.light,
      ],
    );
  }
}
