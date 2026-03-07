import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/settings/settings_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsViewModel viewModel;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsViewModel Tests', () {
    test('Initial state should be default values', () {
      viewModel = SettingsViewModel();

      expect(viewModel.privacyEnabled, false);
    });

    test('Should load saved settings from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'privacy_enabled': true});

      viewModel = SettingsViewModel();
      await Future.delayed(Duration.zero);

      expect(viewModel.privacyEnabled, true);
    });

    test('setPrivacyEnabled should update state and persist', () async {
      viewModel = SettingsViewModel();

      await viewModel.setPrivacyEnabled(true);

      expect(viewModel.privacyEnabled, true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('privacy_enabled'), true);
    });

    test('resetSettings should restore defaults and clear prefs', () async {
      SharedPreferences.setMockInitialValues({'privacy_enabled': true});
      viewModel = SettingsViewModel();
      await Future.delayed(Duration.zero);

      await viewModel.resetSettings();

      expect(viewModel.privacyEnabled, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('privacy_enabled'), false);
    });
  });
}
