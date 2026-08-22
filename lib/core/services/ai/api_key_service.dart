import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/services/preferences_service.dart';

/// La clé vit dans le trousseau du téléphone, indexée par fournisseur :
/// changer de service ne détruit pas la clé du précédent.
class ApiKeyService {
  ApiKeyService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String storagePrefix = 'ai_api_key_';

  /// Les espaces, insécables et zéro-largeur qu'un copier-coller depuis un mail
  /// embarque : ils ne doivent jamais faire échouer une clé valide.
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

  /// Reprend la clé Gemini que le scan de ticket stockait en clair dans les
  /// préférences, puis efface l'ancienne entrée : une seule source de vérité.
  Future<void> migrateLegacyGeminiKey() async {
    final legacy = PreferencesService.getGeminiApiKey();
    if (legacy.isEmpty) return;

    if (!await has(AiProvider.gemini)) {
      await save(AiProvider.gemini, legacy);
    }
    await PreferencesService.setGeminiApiKey('');
  }
}
