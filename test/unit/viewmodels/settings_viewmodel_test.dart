import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/annual_expense_calculation_mode.dart';
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

      expect(
        viewModel.annualExpenseCalculationMode,
        AnnualExpenseCalculationMode.monthlyAmortized,
      );
      expect(viewModel.privacyEnabled, false);
    });

    test('Should load saved settings from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'annual_expense_calculation_mode':
            AnnualExpenseCalculationMode.dateBasedOnly.index,
        'privacy_enabled': true,
      });

      viewModel = SettingsViewModel();
      await Future.delayed(Duration.zero);

      expect(
        viewModel.annualExpenseCalculationMode,
        AnnualExpenseCalculationMode.dateBasedOnly,
      );
      expect(viewModel.privacyEnabled, true);
    });

    test(
      'updateAnnualExpenseCalculationMode should update state and persist',
      () async {
        viewModel = SettingsViewModel();

        await viewModel.updateAnnualExpenseCalculationMode(
          AnnualExpenseCalculationMode.dateBasedOnly,
        );

        expect(
          viewModel.annualExpenseCalculationMode,
          AnnualExpenseCalculationMode.dateBasedOnly,
        );

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getInt('annual_expense_calculation_mode'),
          AnnualExpenseCalculationMode.dateBasedOnly.index,
        );
      },
    );

    test('setPrivacyEnabled should update state and persist', () async {
      viewModel = SettingsViewModel();

      await viewModel.setPrivacyEnabled(true);

      expect(viewModel.privacyEnabled, true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('privacy_enabled'), true);
    });

    test('resetSettings should restore defaults and clear prefs', () async {
      SharedPreferences.setMockInitialValues({
        'annual_expense_calculation_mode': 1,
        'privacy_enabled': true,
      });
      viewModel = SettingsViewModel();
      await Future.delayed(Duration.zero);

      await viewModel.resetSettings();

      expect(
        viewModel.annualExpenseCalculationMode,
        AnnualExpenseCalculationMode.monthlyAmortized,
      );
      expect(viewModel.privacyEnabled, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('annual_expense_calculation_mode'), false);
      expect(prefs.containsKey('privacy_enabled'), false);
    });
  });
}
