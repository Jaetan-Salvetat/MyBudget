import 'package:get/get.dart';
import 'package:mybudget/core/services/preferences_service.dart';

enum AnnualExpenseCalculationMode { monthlyAmortized, dateBasedOnly }

class SettingsController extends GetxController {
  static const String annualExpenseCalculationModeKey =
      'annual_expense_calculation_mode';

  final Rx<AnnualExpenseCalculationMode> annualExpenseCalculationMode =
      AnnualExpenseCalculationMode.monthlyAmortized.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  void loadSettings() {
    final calculationMode = PreferencesService.getAnnualExpenseCalculationMode();
    annualExpenseCalculationMode.value = AnnualExpenseCalculationMode.values[calculationMode];
  }

  Future<void> setAnnualExpenseCalculationMode(
    AnnualExpenseCalculationMode mode,
  ) async {
    annualExpenseCalculationMode.value = mode;
    await PreferencesService.setAnnualExpenseCalculationMode(mode.index);
  }
}
