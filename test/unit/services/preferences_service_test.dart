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

    test('hasSeenUpdateOnboarding is false by default and true after set', () async {
      expect(PreferencesService.hasSeenUpdateOnboarding(), isFalse);
      await PreferencesService.setHasSeenUpdateOnboarding();
      expect(PreferencesService.hasSeenUpdateOnboarding(), isTrue);
    });

    test('isBackgroundCheckEnabled is true by default', () {
      expect(PreferencesService.isBackgroundCheckEnabled(), isTrue);
    });

    test('setBackgroundCheckEnabled persists value', () async {
      await PreferencesService.setBackgroundCheckEnabled(false);
      expect(PreferencesService.isBackgroundCheckEnabled(), isFalse);
      await PreferencesService.setBackgroundCheckEnabled(true);
      expect(PreferencesService.isBackgroundCheckEnabled(), isTrue);
    });

    test('getBackgroundCheckInterval is 24 by default', () {
      expect(PreferencesService.getBackgroundCheckInterval(), 24);
    });

    test('setBackgroundCheckInterval persists value', () async {
      await PreferencesService.setBackgroundCheckInterval(12);
      expect(PreferencesService.getBackgroundCheckInterval(), 12);
      await PreferencesService.setBackgroundCheckInterval(168);
      expect(PreferencesService.getBackgroundCheckInterval(), 168);
    });
  });
}
