import 'package:flutter/material.dart' as legacy;
import 'package:material_ui/material_ui.dart';

class FlutterMaterialMapper {
  FlutterMaterialMapper._();

  static legacy.TextTheme toLegacyTextTheme(TextTheme source) {
    return legacy.TextTheme(
      displayLarge: source.displayLarge,
      displayMedium: source.displayMedium,
      displaySmall: source.displaySmall,
      headlineLarge: source.headlineLarge,
      headlineMedium: source.headlineMedium,
      headlineSmall: source.headlineSmall,
      titleLarge: source.titleLarge,
      titleMedium: source.titleMedium,
      titleSmall: source.titleSmall,
      bodyLarge: source.bodyLarge,
      bodyMedium: source.bodyMedium,
      bodySmall: source.bodySmall,
      labelLarge: source.labelLarge,
      labelMedium: source.labelMedium,
      labelSmall: source.labelSmall,
    );
  }

  static TextTheme toTextTheme(legacy.TextTheme source) {
    return TextTheme(
      displayLarge: source.displayLarge,
      displayMedium: source.displayMedium,
      displaySmall: source.displaySmall,
      headlineLarge: source.headlineLarge,
      headlineMedium: source.headlineMedium,
      headlineSmall: source.headlineSmall,
      titleLarge: source.titleLarge,
      titleMedium: source.titleMedium,
      titleSmall: source.titleSmall,
      bodyLarge: source.bodyLarge,
      bodyMedium: source.bodyMedium,
      bodySmall: source.bodySmall,
      labelLarge: source.labelLarge,
      labelMedium: source.labelMedium,
      labelSmall: source.labelSmall,
    );
  }

  static legacy.ColorScheme toLegacyColorScheme(ColorScheme source) {
    return legacy.ColorScheme(
      brightness: source.brightness,
      primary: source.primary,
      onPrimary: source.onPrimary,
      primaryContainer: source.primaryContainer,
      onPrimaryContainer: source.onPrimaryContainer,
      primaryFixed: source.primaryFixed,
      primaryFixedDim: source.primaryFixedDim,
      onPrimaryFixed: source.onPrimaryFixed,
      onPrimaryFixedVariant: source.onPrimaryFixedVariant,
      secondary: source.secondary,
      onSecondary: source.onSecondary,
      secondaryContainer: source.secondaryContainer,
      onSecondaryContainer: source.onSecondaryContainer,
      secondaryFixed: source.secondaryFixed,
      secondaryFixedDim: source.secondaryFixedDim,
      onSecondaryFixed: source.onSecondaryFixed,
      onSecondaryFixedVariant: source.onSecondaryFixedVariant,
      tertiary: source.tertiary,
      onTertiary: source.onTertiary,
      tertiaryContainer: source.tertiaryContainer,
      onTertiaryContainer: source.onTertiaryContainer,
      tertiaryFixed: source.tertiaryFixed,
      tertiaryFixedDim: source.tertiaryFixedDim,
      onTertiaryFixed: source.onTertiaryFixed,
      onTertiaryFixedVariant: source.onTertiaryFixedVariant,
      error: source.error,
      onError: source.onError,
      errorContainer: source.errorContainer,
      onErrorContainer: source.onErrorContainer,
      surface: source.surface,
      onSurface: source.onSurface,
      surfaceDim: source.surfaceDim,
      surfaceBright: source.surfaceBright,
      surfaceContainerLowest: source.surfaceContainerLowest,
      surfaceContainerLow: source.surfaceContainerLow,
      surfaceContainer: source.surfaceContainer,
      surfaceContainerHigh: source.surfaceContainerHigh,
      surfaceContainerHighest: source.surfaceContainerHighest,
      onSurfaceVariant: source.onSurfaceVariant,
      outline: source.outline,
      outlineVariant: source.outlineVariant,
      shadow: source.shadow,
      scrim: source.scrim,
      inverseSurface: source.inverseSurface,
      onInverseSurface: source.onInverseSurface,
      inversePrimary: source.inversePrimary,
      surfaceTint: source.surfaceTint,
    );
  }

  static legacy.ThemeData toLegacyThemeData(ThemeData source) {
    return legacy.ThemeData.from(
      colorScheme: toLegacyColorScheme(source.colorScheme),
      textTheme: toLegacyTextTheme(source.textTheme),
    );
  }
}
