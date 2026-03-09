import 'package:flutter/material.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_theme.dart';

part 'theme_provider.g.dart';

class ThemeState {
  final AppThemeType themeType;
  final ThemeMode themeMode;

  const ThemeState({
    required this.themeType,
    required this.themeMode,
  });

  ThemeState copyWith({
    AppThemeType? themeType,
    ThemeMode? themeMode,
  }) {
    return ThemeState(
      themeType: themeType ?? this.themeType,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  @override
  ThemeState build() {
    return ThemeState(
      themeType: PreferencesService.getThemeType(),
      themeMode: PreferencesService.getThemeMode(),
    );
  }

  void setThemeType(AppThemeType themeType) {
    state = state.copyWith(themeType: themeType);
    PreferencesService.setThemeType(themeType);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    PreferencesService.setThemeMode(mode);
  }

  ThemeData getLightTheme({ColorScheme? dynamicColorScheme}) {
    return AppTheme.generateTheme(
      Brightness.light,
      state.themeType,
      dynamicColorScheme: dynamicColorScheme,
    );
  }

  ThemeData getDarkTheme({ColorScheme? dynamicColorScheme}) {
    return AppTheme.generateTheme(
      Brightness.dark,
      state.themeType,
      dynamicColorScheme: dynamicColorScheme,
    );
  }
}
