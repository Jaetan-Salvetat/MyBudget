import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeNotifier', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PreferencesService.init();
    });

    ProviderContainer makeContainer() => ProviderContainer();

    test('defaults to ThemeMode.system', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(container.read(themeProvider).themeMode, ThemeMode.system);
    });

    test('setThemeMode updates state and persists', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);

      expect(container.read(themeProvider).themeMode, ThemeMode.dark);
      expect(PreferencesService.getThemeMode(), ThemeMode.dark);
    });

    test('Initialization with saved themeMode', () async {
      SharedPreferences.setMockInitialValues({
        PreferencesService.keyThemeMode: ThemeMode.light.name,
      });
      await PreferencesService.init();

      final container = makeContainer();
      addTearDown(container.dispose);

      expect(container.read(themeProvider).themeMode, ThemeMode.light);
    });
  });
}
