import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeNotifier Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PreferencesService.init();
    });

    ProviderContainer makeContainer() {
      return ProviderContainer();
    }

    test('Initial state should be loaded from preferences (defaults)', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(themeProvider);
      expect(state.themeMode, ThemeMode.system);
      expect(state.themeType, AppThemeType.purple);
    });

    test('setThemeMode should update state and persist preference', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);

      expect(container.read(themeProvider).themeMode, ThemeMode.dark);
      expect(PreferencesService.getThemeMode(), ThemeMode.dark);
    });

    test('setThemeType should update state and persist preference', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).setThemeType(AppThemeType.green);

      expect(container.read(themeProvider).themeType, AppThemeType.green);
      expect(PreferencesService.getThemeType(), AppThemeType.green);
    });

    test('setThemeType to dynamicColor should update state', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).setThemeType(AppThemeType.dynamicColor);

      expect(container.read(themeProvider).themeType, AppThemeType.dynamicColor);
      expect(PreferencesService.getThemeType(), AppThemeType.dynamicColor);
    });

    test('getLightTheme should return light theme with correct seed color', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).setThemeType(AppThemeType.blue);
      final theme = container.read(themeProvider.notifier).getLightTheme();

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('getDarkTheme should return dark theme with correct seed color', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).setThemeType(AppThemeType.red);
      final theme = container.read(themeProvider.notifier).getDarkTheme();

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('getLightTheme with dynamic color should use dynamic scheme', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).setThemeType(AppThemeType.dynamicColor);

      final dynamicScheme = ColorScheme.fromSeed(
        seedColor: Colors.yellow,
        brightness: Brightness.light,
      );

      final theme = container.read(themeProvider.notifier).getLightTheme(dynamicColorScheme: dynamicScheme);

      expect(theme.colorScheme, dynamicScheme);
    });

    test(
      'getLightTheme with dynamic color but null scheme should fallback to seed',
      () {
        final container = makeContainer();
        addTearDown(container.dispose);

        container.read(themeProvider.notifier).setThemeType(AppThemeType.dynamicColor);

        final theme = container.read(themeProvider.notifier).getLightTheme();

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

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(themeProvider);
      expect(state.themeMode, ThemeMode.light);
      expect(state.themeType, AppThemeType.orange);
    });
  });
}
