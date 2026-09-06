import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/services/preferences_service.dart';

class ApiKeyService {
  ApiKeyService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String storagePrefix = 'ai_api_key_';

  static final RegExp _invisibleCharacters = RegExp(
    '[\\s\u00A0\u200B-\u200D\uFEFF]',
  );

  final FlutterSecureStorage _storage;

  static String sanitize(String raw) =>
      raw.replaceAll(_invisibleCharacters, '');

  static String _storageKey(AiProvider provider) =>
      '$storagePrefix${provider.id}';

  Future<String?> read(AiProvider provider) async {
    final stored = await _storage.read(key: _storageKey(provider));
    if (stored == null || stored.isEmpty) return null;
    return stored;
  }

  Future<bool> has(AiProvider provider) async =>
      await read(provider) != null;

  Future<void> save(AiProvider provider, String key) =>
      _storage.write(key: _storageKey(provider), value: sanitize(key));

  Future<void> delete(AiProvider provider) =>
      _storage.delete(key: _storageKey(provider));

  Future<void> migrateLegacyGeminiKey() async {
    final legacy = PreferencesService.getGeminiApiKey();
    if (legacy.isEmpty) return;

    if (!await has(AiProvider.gemini)) {
      await save(AiProvider.gemini, legacy);
    }
    await PreferencesService.setGeminiApiKey('');
  }
}
