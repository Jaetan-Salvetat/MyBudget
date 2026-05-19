import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static late SharedPreferences _prefs;

  static const String keyIsFirstLaunch = 'isFirstLaunch';
  static const String keyThemeMode = 'themeMode';
  static const String keyLanguage = 'language';

  static const String keyExportFrequency = 'exportFrequency';
  static const String keySkipAuth = 'skipAuth';
  static const String keyIsCategoriesCreated = 'isCategoriesCreated';
  static const String keyHasSeenUpdateOnboarding = 'hasSeenUpdateOnboarding';

  static const String keyLastScanTimestamp = 'lastScanTimestamp';
  static const String keyQuickAddCount = 'quickAddCount';
  static const String keyQuickAddMonth = 'quickAddMonth';

  static const String keyExpensesGroupBy = 'expensesGroupBy';
  static const String keyExpensesSortBy = 'expensesSortBy';
  static const String keyExpensesRecurringExpanded = 'expensesRecurringExpanded';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool isFirstLaunch() {
    return _prefs.getBool(keyIsFirstLaunch) ?? true;
  }

  static Future<void> setNotFirstLaunch() async {
    await _prefs.setBool(keyIsFirstLaunch, false);
  }

  static ThemeMode getThemeMode() {
    return ThemeMode.values.firstWhere(
      (element) => element.name == _prefs.getString(keyThemeMode),
      orElse: () => ThemeMode.system,
    );
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(keyThemeMode, mode.name);
  }

  static String getLanguage() {
    return _prefs.getString(keyLanguage) ?? 'fr';
  }

  static Future<void> setLanguage(String language) async {
    await _prefs.setString(keyLanguage, language);
  }


  static int getExportFrequency() {
    return _prefs.getInt(keyExportFrequency) ?? 0;
  }

  static Future<void> setExportFrequency(int frequency) async {
    await _prefs.setInt(keyExportFrequency, frequency);
  }

  static bool shouldSkipAuth() {
    return _prefs.getBool(keySkipAuth) ?? true;
  }

  static Future<void> setSkipAuth(bool skip) async {
    await _prefs.setBool(keySkipAuth, skip);
  }

  static bool isCategoriesCreated() {
    return _prefs.getBool(keyIsCategoriesCreated) ?? false;
  }

  static Future<void> setCategoriesCreated() async {
    await _prefs.setBool(keyIsCategoriesCreated, true);
  }

  static bool hasSeenUpdateOnboarding() {
    return _prefs.getBool(keyHasSeenUpdateOnboarding) ?? false;
  }

  static Future<void> setHasSeenUpdateOnboarding() async {
    await _prefs.setBool(keyHasSeenUpdateOnboarding, true);
  }


  static int getLastScanTimestamp() {
    return _prefs.getInt(keyLastScanTimestamp) ?? 0;
  }

  static Future<void> setLastScanTimestamp(int timestamp) async {
    await _prefs.setInt(keyLastScanTimestamp, timestamp);
  }

  static int getQuickAddCount() {
    final storedMonth = _prefs.getString(keyQuickAddMonth) ?? '';
    final currentMonth =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    if (storedMonth != currentMonth) {
      return 0;
    }
    return _prefs.getInt(keyQuickAddCount) ?? 0;
  }

  static Future<void> incrementQuickAddCount() async {
    final currentMonth =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final storedMonth = _prefs.getString(keyQuickAddMonth) ?? '';
    if (storedMonth != currentMonth) {
      await _prefs.setString(keyQuickAddMonth, currentMonth);
      await _prefs.setInt(keyQuickAddCount, 1);
    } else {
      final current = _prefs.getInt(keyQuickAddCount) ?? 0;
      await _prefs.setInt(keyQuickAddCount, current + 1);
    }
  }

  static String getExpensesGroupBy() {
    return _prefs.getString(keyExpensesGroupBy) ?? 'day';
  }

  static Future<void> setExpensesGroupBy(String value) async {
    await _prefs.setString(keyExpensesGroupBy, value);
  }

  static String getExpensesSortBy() {
    return _prefs.getString(keyExpensesSortBy) ?? 'dateDesc';
  }

  static Future<void> setExpensesSortBy(String value) async {
    await _prefs.setString(keyExpensesSortBy, value);
  }

  static bool getExpensesRecurringExpanded() {
    return _prefs.getBool(keyExpensesRecurringExpanded) ?? false;
  }

  static Future<void> setExpensesRecurringExpanded(bool value) async {
    await _prefs.setBool(keyExpensesRecurringExpanded, value);
  }

  static Future<void> clearAll() async {
    await _prefs.clear();
  }
}
