import 'package:flutter/material.dart';

extension ThemeModeDisplay on ThemeMode {
  String get label => switch (this) {
    ThemeMode.system => 'Automatique',
    ThemeMode.light => 'Clair',
    ThemeMode.dark => 'Sombre',
  };

  String get description => switch (this) {
    ThemeMode.system => 'Suit le réglage du système.',
    ThemeMode.light => 'Toujours clair, quelle que soit l\'heure.',
    ThemeMode.dark => 'Toujours sombre, quelle que soit l\'heure.',
  };
}
