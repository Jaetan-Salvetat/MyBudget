import 'package:flutter/material.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'app_theme.dart';

class ThemeViewModel extends ChangeNotifier {
  AppThemeType _themeType = AppThemeType.purple;
  ThemeMode _themeMode = ThemeMode.system;

  AppThemeType get themeType => _themeType;
  ThemeMode get themeMode => _themeMode;

  ThemeViewModel() {
    _loadTheme();
  }

  void _loadTheme() {
    _themeType = PreferencesService.getThemeType();
    _themeMode = PreferencesService.getThemeMode();
    notifyListeners();
  }

  void setThemeType(AppThemeType themeType) {
    _themeType = themeType;
    PreferencesService.setThemeType(themeType);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    PreferencesService.setThemeMode(mode);
    notifyListeners();
  }

  ThemeData getLightTheme({ColorScheme? dynamicColorScheme}) {
    return AppTheme.generateTheme(
      Brightness.light,
      _themeType,
      dynamicColorScheme: dynamicColorScheme,
    );
  }

  ThemeData getDarkTheme({ColorScheme? dynamicColorScheme}) {
    return AppTheme.generateTheme(
      Brightness.dark,
      _themeType,
      dynamicColorScheme: dynamicColorScheme,
    );
  }
}
