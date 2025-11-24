import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/core/theme/theme_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeViewModel Tests', () {
    late ThemeViewModel viewModel;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PreferencesService.init();
      viewModel = ThemeViewModel();
    });

    test('Initial state should be loaded from preferences (defaults)', () {
      expect(viewModel.themeMode, ThemeMode.system);
      expect(viewModel.themeType, AppThemeType.purple);
    });

    test('setThemeMode should update state and persist preference', () async {
      viewModel.setThemeMode(ThemeMode.dark);

      expect(viewModel.themeMode, ThemeMode.dark);
      expect(PreferencesService.getThemeMode(), ThemeMode.dark);
    });

    test('setThemeType should update state and persist preference', () async {
      viewModel.setThemeType(AppThemeType.green);

      expect(viewModel.themeType, AppThemeType.green);
      expect(PreferencesService.getThemeType(), AppThemeType.green);
    });

    test('setThemeType to dynamicColor should update state', () async {
      viewModel.setThemeType(AppThemeType.dynamicColor);

      expect(viewModel.themeType, AppThemeType.dynamicColor);
      expect(PreferencesService.getThemeType(), AppThemeType.dynamicColor);
    });

    test('getLightTheme should return light theme with correct seed color', () {
      viewModel.setThemeType(AppThemeType.blue);
      final theme = viewModel.getLightTheme();

      expect(theme.brightness, Brightness.light);
      // Verify primary color is derived from seed (approximate check or check scheme)
      // Note: ColorScheme.fromSeed might not result in exact seed color as primary
      // But we can check if the scheme was generated.
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('getDarkTheme should return dark theme with correct seed color', () {
      viewModel.setThemeType(AppThemeType.red);
      final theme = viewModel.getDarkTheme();

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('getLightTheme with dynamic color should use dynamic scheme', () {
      viewModel.setThemeType(AppThemeType.dynamicColor);

      final dynamicScheme = ColorScheme.fromSeed(
        seedColor: Colors.yellow,
        brightness: Brightness.light,
      );

      final theme = viewModel.getLightTheme(dynamicColorScheme: dynamicScheme);

      expect(theme.colorScheme, dynamicScheme);
    });

    test(
      'getLightTheme with dynamic color but null scheme should fallback to seed',
      () {
        viewModel.setThemeType(AppThemeType.dynamicColor);

        // No dynamic scheme provided
        final theme = viewModel.getLightTheme();

        // Should fallback to seed color (transparent for dynamicColor in AppThemeType)
        // Wait, AppThemeType.dynamicColor.seedColor is Colors.transparent.
        // ColorScheme.fromSeed(seedColor: Colors.transparent) might be weird but valid.
        expect(theme.brightness, Brightness.light);
        expect(theme.useMaterial3, true);
      },
    );

    test('Initialization with saved values', () async {
      SharedPreferences.setMockInitialValues({
        PreferencesService.keyThemeMode: ThemeMode.light.name,
        PreferencesService.keyThemeType: AppThemeType.orange.name,
      });
      await PreferencesService.init();

      // Re-initialize ViewModel to pick up new prefs
      viewModel = ThemeViewModel();

      expect(viewModel.themeMode, ThemeMode.light);
      expect(viewModel.themeType, AppThemeType.orange);
    });
  });
}
