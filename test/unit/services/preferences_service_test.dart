import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/services/preferences_service.dart';
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

    test('getGeminiApiKey returns an empty key by default', () {
      expect(PreferencesService.getGeminiApiKey(), isEmpty);
    });

    test('setGeminiApiKey persists the key', () async {
      await PreferencesService.setGeminiApiKey('user-key');
      expect(PreferencesService.getGeminiApiKey(), 'user-key');
    });

    test('getThemeMode returns ThemeMode.system by default', () {
      expect(PreferencesService.getThemeMode(), ThemeMode.system);
    });

    test(
      'setThemeMode persists and getThemeMode returns the set value',
      () async {
        await PreferencesService.setThemeMode(ThemeMode.dark);
        expect(PreferencesService.getThemeMode(), ThemeMode.dark);
      },
    );

    test(
      'hasSeenUpdateOnboarding is false by default and true after set',
      () async {
        expect(PreferencesService.hasSeenUpdateOnboarding(), isFalse);
        await PreferencesService.setHasSeenUpdateOnboarding();
        expect(PreferencesService.hasSeenUpdateOnboarding(), isTrue);
      },
    );

    test('getAiModel returns the fallback model by default', () {
      expect(PreferencesService.getAiModel(), AiModel.fallback);
    });

    test('setAiModel persists the chosen model', () async {
      await PreferencesService.setAiModel(AiModel.flash37);
      expect(PreferencesService.getAiModel(), AiModel.flash37);
    });

    test('getAiModel falls back when the stored id is unknown', () async {
      SharedPreferences.setMockInitialValues({
        PreferencesService.keyAiModel: 'gemini-9-turbo',
      });
      await PreferencesService.init();

      expect(PreferencesService.getAiModel(), AiModel.fallback);
    });

    test('getRevenuesGroupBy returns nothing by default', () {
      expect(PreferencesService.getRevenuesGroupBy(), isNull);
    });

    test('setRevenuesGroupBy persists the axis', () async {
      await PreferencesService.setRevenuesGroupBy('beneficiary');
      expect(PreferencesService.getRevenuesGroupBy(), 'beneficiary');
    });
  });
}
