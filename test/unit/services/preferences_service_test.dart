import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();
  });

  group('PreferencesService', () {
    test('isFirstLaunch returns true by default', () {
      expect(PreferencesService.isFirstLaunch(), isTrue);
    });

    test('setNotFirstLaunch makes isFirstLaunch return false', () async {
      await PreferencesService.setNotFirstLaunch();
      expect(PreferencesService.isFirstLaunch(), isFalse);
    });

    test('getThemeMode returns ThemeMode.system by default', () {
      expect(PreferencesService.getThemeMode(), ThemeMode.system);
    });

    test('setThemeMode persists and getThemeMode returns the set value', () async {
      await PreferencesService.setThemeMode(ThemeMode.dark);
      expect(PreferencesService.getThemeMode(), ThemeMode.dark);
    });

    test('getThemeType returns AppThemeType.purple by default', () {
      expect(PreferencesService.getThemeType(), AppThemeType.purple);
    });

    test('isCategoriesCreated is false by default and true after setCategoriesCreated', () async {
      expect(PreferencesService.isCategoriesCreated(), isFalse);
      await PreferencesService.setCategoriesCreated();
      expect(PreferencesService.isCategoriesCreated(), isTrue);
    });
  });
}
