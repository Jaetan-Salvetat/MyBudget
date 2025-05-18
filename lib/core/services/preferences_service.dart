import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static late SharedPreferences _prefs;

  static const String keyIsFirstLaunch = 'isFirstLaunch';
  static const String keyThemeMode = 'themeMode';
  static const String keyLanguage = 'language';
  static const String keyIsNotificationsEnabled = 'isNotificationsEnabled';
  static const String keyExportFrequency = 'exportFrequency';
  static const String keySkipAuth = 'skipAuth';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool isFirstLaunch() {
    return _prefs.getBool(keyIsFirstLaunch) ?? true;
  }

  static Future<void> setNotFirstLaunch() async {
    await _prefs.setBool(keyIsFirstLaunch, false);
  }

  static int getThemeMode() {
    return _prefs.getInt(keyThemeMode) ?? 0;
  }

  static Future<void> setThemeMode(int mode) async {
    await _prefs.setInt(keyThemeMode, mode);
  }

  static String getLanguage() {
    return _prefs.getString(keyLanguage) ?? 'fr';
  }

  static Future<void> setLanguage(String language) async {
    await _prefs.setString(keyLanguage, language);
  }

  static bool isNotificationsEnabled() {
    return _prefs.getBool(keyIsNotificationsEnabled) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(keyIsNotificationsEnabled, enabled);
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

  static Future<void> clearAll() async {
    await _prefs.clear();
  }
}
