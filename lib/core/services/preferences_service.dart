import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static late SharedPreferences _prefs;

  static const String keyIsFirstLaunch = 'isFirstLaunch';
  static const String keyThemeMode = 'themeMode';
  static const String keyLanguage = 'language';

  static const String keyExportFrequency = 'exportFrequency';
  static const String keySkipAuth = 'skipAuth';
  static const String keyHasSeenUpdateOnboarding = 'hasSeenUpdateOnboarding';
  static const String keyLegacyCategoryMigrationDone =
      'legacyCategoryMigrationDone';
  static const String keyLegacyLoanDefaultsMigrationDone =
      'legacyLoanDefaultsMigrationDone';

  static const String keyGeminiApiKey = 'geminiApiKey';

  static const String keyQuickAddEnabled = 'quickAddEnabled';
  static const String keyQuickAddEngineMode = 'quickAddEngineMode';
  static const String keyGeminiNanoScan = 'geminiNanoScan';
  static const String keyAiProvider = 'aiProvider';
  static const String keyAiModel = 'aiModel';
  static const String keyAiCloudConsent = 'aiCloudConsent';
  static const String keyAiFailureTimestamps = 'aiFailureTimestamps';

  static const String keyQuickAddAccountId = 'quickAddAccountId';

  static const String keyExpensesGroupBy = 'expensesGroupBy';
  static const String keyExpensesSortBy = 'expensesSortBy';
  static const String keyRevenuesGroupBy = 'revenuesGroupBy';

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

  static String getGeminiApiKey() {
    return _prefs.getString(keyGeminiApiKey) ?? '';
  }

  static Future<void> setGeminiApiKey(String key) async {
    await _prefs.setString(keyGeminiApiKey, key);
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

  static bool hasSeenUpdateOnboarding() {
    return _prefs.getBool(keyHasSeenUpdateOnboarding) ?? false;
  }

  static Future<void> setHasSeenUpdateOnboarding() async {
    await _prefs.setBool(keyHasSeenUpdateOnboarding, true);
  }

  static bool isLegacyCategoryMigrationDone() {
    return _prefs.getBool(keyLegacyCategoryMigrationDone) ?? false;
  }

  static Future<void> setLegacyCategoryMigrationDone() async {
    await _prefs.setBool(keyLegacyCategoryMigrationDone, true);
  }

  static bool isLegacyLoanDefaultsMigrationDone() {
    return _prefs.getBool(keyLegacyLoanDefaultsMigrationDone) ?? false;
  }

  static Future<void> setLegacyLoanDefaultsMigrationDone() async {
    await _prefs.setBool(keyLegacyLoanDefaultsMigrationDone, true);
  }

  static bool isQuickAddEnabled() {
    return _prefs.getBool(keyQuickAddEnabled) ?? true;
  }

  static Future<void> setQuickAddEnabled(bool enabled) async {
    await _prefs.setBool(keyQuickAddEnabled, enabled);
  }

  static bool isGeminiNanoScanEnabled() {
    return _prefs.getBool(keyGeminiNanoScan) ?? false;
  }

  static Future<void> setGeminiNanoScanEnabled(bool enabled) async {
    await _prefs.setBool(keyGeminiNanoScan, enabled);
  }

  static QuickAddEngineMode getQuickAddEngineMode() {
    return QuickAddEngineMode.fromId(_prefs.getString(keyQuickAddEngineMode));
  }

  static Future<void> setQuickAddEngineMode(QuickAddEngineMode mode) async {
    await _prefs.setString(keyQuickAddEngineMode, mode.id);
  }

  static AiProvider getAiProvider() {
    return AiProvider.fromId(_prefs.getString(keyAiProvider));
  }

  static Future<void> setAiProvider(AiProvider provider) async {
    await _prefs.setString(keyAiProvider, provider.id);
  }

  static AiModel getAiModel() {
    return AiModel.fromId(_prefs.getString(keyAiModel));
  }

  static Future<void> setAiModel(AiModel model) async {
    await _prefs.setString(keyAiModel, model.id);
  }

  static bool hasAcceptedAiCloudConsent() {
    return _prefs.getBool(keyAiCloudConsent) ?? false;
  }

  static Future<void> setAiCloudConsent(bool accepted) async {
    await _prefs.setBool(keyAiCloudConsent, accepted);
  }

  static List<int> getAiFailureTimestamps() {
    final stored = _prefs.getStringList(keyAiFailureTimestamps) ?? const [];
    return stored.map(int.tryParse).nonNulls.toList();
  }

  static Future<void> setAiFailureTimestamps(List<int> timestamps) async {
    await _prefs.setStringList(
      keyAiFailureTimestamps,
      timestamps.map((timestamp) => timestamp.toString()).toList(),
    );
  }

  static int? getQuickAddAccountId() {
    return _prefs.getInt(keyQuickAddAccountId);
  }

  static Future<void> setQuickAddAccountId(int accountId) async {
    await _prefs.setInt(keyQuickAddAccountId, accountId);
  }

  static Future<void> clearQuickAddAccountId() async {
    await _prefs.remove(keyQuickAddAccountId);
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

  static String? getRevenuesGroupBy() {
    return _prefs.getString(keyRevenuesGroupBy);
  }

  static Future<void> setRevenuesGroupBy(String value) async {
    await _prefs.setString(keyRevenuesGroupBy, value);
  }

  static Future<void> clearAll() async {
    await _prefs.clear();
  }
}
