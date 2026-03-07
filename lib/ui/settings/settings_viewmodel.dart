import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  static const String _privacyKey = 'privacy_enabled';

  bool _privacyEnabled = false;

  bool get privacyEnabled => _privacyEnabled;

  SettingsViewModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _privacyEnabled = prefs.getBool(_privacyKey) ?? false;
    notifyListeners();
  }

  Future<void> setPrivacyEnabled(bool enabled) async {
    if (_privacyEnabled == enabled) return;

    _privacyEnabled = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyKey, enabled);
  }

  Future<void> resetSettings() async {
    _privacyEnabled = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_privacyKey);
  }
}
