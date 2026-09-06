import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

class ThemeState {
  const ThemeState({required this.themeMode});
  final ThemeMode themeMode;

  ThemeState copyWith({ThemeMode? themeMode}) {
    return ThemeState(themeMode: themeMode ?? this.themeMode);
  }
}

@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  @override
  ThemeState build() {
    return ThemeState(themeMode: PreferencesService.getThemeMode());
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    PreferencesService.setThemeMode(mode);
  }
}
