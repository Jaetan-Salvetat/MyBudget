import 'package:flutter/material.dart';

class SeedOption {
  const SeedOption({required this.label, required this.color});

  final String label;
  final Color color;
}

class ThemeController extends ChangeNotifier {
  ThemeController({
    ThemeMode initialMode = ThemeMode.dark,
    Color? initialSeed,
  })  : _mode = initialMode,
        _seedColor = initialSeed ?? seedOptions.first.color;

  static const List<SeedOption> seedOptions = <SeedOption>[
    SeedOption(label: 'Violet', color: Color(0xFF7C5CFF)),
    SeedOption(label: 'Vert', color: Color(0xFF2E9E63)),
    SeedOption(label: 'Orange', color: Color(0xFFE08A2A)),
    SeedOption(label: 'Rose', color: Color(0xFFE5527A)),
  ];

  ThemeMode _mode;
  Color _seedColor;

  ThemeMode get mode => _mode;
  Color get seedColor => _seedColor;

  void setMode(ThemeMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
  }

  void setSeed(Color color) {
    if (color == _seedColor) return;
    _seedColor = color;
    notifyListeners();
  }
}
