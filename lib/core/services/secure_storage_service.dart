import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _geminiApiKeyKey = 'gemini_api_key';

  @visibleForTesting
  static set storage(FlutterSecureStorage value) => _storage = value;

  static Future<String?> getGeminiApiKey() async {
    return _storage.read(key: _geminiApiKeyKey);
  }

  static Future<void> setGeminiApiKey(String apiKey) async {
    await _storage.write(key: _geminiApiKeyKey, value: apiKey);
  }

  static Future<void> deleteGeminiApiKey() async {
    await _storage.delete(key: _geminiApiKeyKey);
  }

  static Future<bool> hasGeminiApiKey() async {
    final key = await _storage.read(key: _geminiApiKeyKey);
    return key != null;
  }
}
