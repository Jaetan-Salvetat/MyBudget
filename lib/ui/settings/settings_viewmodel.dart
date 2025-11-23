import 'package:flutter/material.dart';
import 'package:mybudget/core/enums/annual_expense_calculation_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _calculationModeKey = 'annual_expense_calculation_mode';
  static const String _privacyKey = 'privacy_enabled';

  ThemeMode _themeMode = ThemeMode.system;
  AnnualExpenseCalculationMode _annualExpenseCalculationMode =
      AnnualExpenseCalculationMode.monthlyAmortized;
  bool _privacyEnabled = false;

  ThemeMode get themeMode => _themeMode;
  AnnualExpenseCalculationMode get annualExpenseCalculationMode =>
      _annualExpenseCalculationMode;
  bool get privacyEnabled => _privacyEnabled;

  SettingsViewModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    final calculationModeIndex = prefs.getInt(_calculationModeKey);
    if (calculationModeIndex != null) {
      _annualExpenseCalculationMode =
          AnnualExpenseCalculationMode.values[calculationModeIndex];
    }

    _privacyEnabled = prefs.getBool(_privacyKey) ?? false;

    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> updateAnnualExpenseCalculationMode(
    AnnualExpenseCalculationMode mode,
  ) async {
    if (_annualExpenseCalculationMode == mode) return;

    _annualExpenseCalculationMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_calculationModeKey, mode.index);
  }

  Future<void> setPrivacyEnabled(bool enabled) async {
    if (_privacyEnabled == enabled) return;

    _privacyEnabled = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyKey, enabled);
  }
}
