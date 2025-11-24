import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0),
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      },
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0),
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      },
    ),
  );

  static ThemeData generateTheme(
    Brightness brightness,
    AppThemeType themeType, {
    ColorScheme? dynamicColorScheme,
  }) {
    ColorScheme? scheme;

    if (themeType == AppThemeType.dynamicColor && dynamicColorScheme != null) {
      scheme = dynamicColorScheme;
    } else {
      scheme = ColorScheme.fromSeed(
        seedColor: themeType.seedColor,
        brightness: brightness,
      );
    }

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }
}

enum AppThemeType {
  dynamicColor,
  purple,
  green,
  blue,
  cyan,
  red,
  orange;

  Color get seedColor {
    switch (this) {
      case AppThemeType.dynamicColor:
        return Colors.transparent; // Special case handled in UI
      case AppThemeType.blue:
        return const Color(0xFF1565C0);
      case AppThemeType.purple:
        return const Color(0xFF673AB7);
      case AppThemeType.green:
        return const Color(0xFF2E7D32);
      case AppThemeType.red:
        return const Color(0xFFD32F2F);
      case AppThemeType.orange:
        return const Color(0xFFEF6C00);
      case AppThemeType.cyan:
        return const Color(0xFF00838F);
    }
  }

  String get label {
    switch (this) {
      case AppThemeType.dynamicColor:
        return 'Dynamique';
      case AppThemeType.blue:
        return 'Bleu';
      case AppThemeType.purple:
        return 'Violet';
      case AppThemeType.green:
        return 'Vert';
      case AppThemeType.red:
        return 'Rouge';
      case AppThemeType.orange:
        return 'Orange';
      case AppThemeType.cyan:
        return 'Cyan';
    }
  }
}
