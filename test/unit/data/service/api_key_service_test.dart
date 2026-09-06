import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/data/service/ai/api_key_service.dart';
import 'package:mybudget/data/service/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiKeyService service;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();
    service = ApiKeyService();
  });

  group('ApiKeyService.sanitize', () {
    test('drops the whitespace a copy-paste drags along', () {
      expect(ApiKeyService.sanitize('  AIza key \n'), 'AIzakey');
    });

    test('drops non-breaking and zero-width characters', () {
      expect(ApiKeyService.sanitize('AIza abc​def﻿'), 'AIzaabcdef');
    });

    test('leaves a clean key untouched', () {
      expect(ApiKeyService.sanitize('AIzaSyA-1_2'), 'AIzaSyA-1_2');
    });
  });

  group('ApiKeyService storage', () {
    test('reads back what was saved', () async {
      await service.save(AiProvider.gemini, 'AIzaSyClean');

      expect(await service.read(AiProvider.gemini), 'AIzaSyClean');
      expect(await service.has(AiProvider.gemini), isTrue);
    });

    test('sanitizes on the way in', () async {
      await service.save(AiProvider.gemini, ' AIzaSyClean\n');

      expect(await service.read(AiProvider.gemini), 'AIzaSyClean');
    });

    test('reports no key before anything is saved', () async {
      expect(await service.read(AiProvider.gemini), isNull);
      expect(await service.has(AiProvider.gemini), isFalse);
    });

    test('delete removes the key', () async {
      await service.save(AiProvider.gemini, 'AIzaSyClean');
      await service.delete(AiProvider.gemini);

      expect(await service.has(AiProvider.gemini), isFalse);
    });
  });

  group('ApiKeyService.migrateLegacyGeminiKey', () {
    test('moves the plaintext key into the keychain and clears it', () async {
      await PreferencesService.setGeminiApiKey('AIzaLegacy');

      await service.migrateLegacyGeminiKey();

      expect(await service.read(AiProvider.gemini), 'AIzaLegacy');
      expect(PreferencesService.getGeminiApiKey(), isEmpty);
    });

    test('never overwrites a key already in the keychain', () async {
      await service.save(AiProvider.gemini, 'AIzaCurrent');
      await PreferencesService.setGeminiApiKey('AIzaLegacy');

      await service.migrateLegacyGeminiKey();

      expect(await service.read(AiProvider.gemini), 'AIzaCurrent');
      expect(PreferencesService.getGeminiApiKey(), isEmpty);
    });

    test('does nothing when there is no legacy key', () async {
      await service.migrateLegacyGeminiKey();

      expect(await service.has(AiProvider.gemini), isFalse);
    });
  });
}
