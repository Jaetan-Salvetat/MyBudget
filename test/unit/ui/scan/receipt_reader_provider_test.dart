import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/enums/gemini_nano_channel.dart';
import 'package:mybudget/core/enums/gemini_nano_preference.dart';
import 'package:mybudget/core/enums/gemini_nano_status.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/ai/api_key_service.dart';
import 'package:mybudget/core/services/ai/gemini_nano_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/scan/scan_provider.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:mybudget/ui/settings/gemini_nano_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubKeyService implements ApiKeyService {
  _StubKeyService(this.key);

  final String? key;

  @override
  Future<String?> read(AiProvider provider) async => key;

  @override
  Future<bool> has(AiProvider provider) async => key != null;

  @override
  Future<void> save(AiProvider provider, String rawKey) async {}

  @override
  Future<void> delete(AiProvider provider) async {}

  @override
  Future<void> migrateLegacyGeminiKey() async {}
}

class _StubService extends GeminiNanoService {
  const _StubService(this.answer);

  final GeminiNanoStatus answer;

  @override
  Future<GeminiNanoStatus> status(
    GeminiNanoChannel channel,
    GeminiNanoPreference preference,
  ) async => answer;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerOf(
    GeminiNanoStatus status, {
    String? apiKey,
  }) async {
    final container = ProviderContainer(
      overrides: [
        geminiNanoServiceProvider.overrideWithValue(_StubService(status)),
        apiKeyServiceProvider.overrideWithValue(_StubKeyService(apiKey)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(geminiNanoStatusProvider.future);
    await container.read(hasStoredApiKeyProvider.future);
    return container;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();
  });

  group('nanoReceiptReaderProvider', () {
    test('rien tant que la lecture des tickets n\'est pas activée', () async {
      final container = await containerOf(GeminiNanoStatus.available);

      expect(container.read(nanoReceiptReaderProvider), isNull);
    });

    test('rien tant que le modèle n\'est pas installé', () async {
      await PreferencesService.setGeminiNanoScanEnabled(true);
      final container = await containerOf(GeminiNanoStatus.downloadable);

      expect(container.read(nanoReceiptReaderProvider), isNull);
    });

    test('un lecteur dès que le modèle est prêt et le réglage actif', () async {
      await PreferencesService.setGeminiNanoScanEnabled(true);
      final container = await containerOf(GeminiNanoStatus.available);

      expect(container.read(nanoReceiptReaderProvider), isNotNull);
    });

    test('le mode clé personnelle écarte le lecteur sur l\'appareil', () async {
      await PreferencesService.setGeminiNanoScanEnabled(true);
      await PreferencesService.setQuickAddEngineMode(QuickAddEngineMode.apiKey);
      final container = await containerOf(
        GeminiNanoStatus.available,
        apiKey: 'AIza-cle',
      );

      expect(container.read(nanoReceiptReaderProvider), isNull);
    });

    test('couper le réglage retire le lecteur', () async {
      await PreferencesService.setGeminiNanoScanEnabled(true);
      final container = await containerOf(GeminiNanoStatus.available);

      await container.read(geminiNanoScanProvider.notifier).setEnabled(false);

      expect(container.read(nanoReceiptReaderProvider), isNull);
    });
  });

  group('cloudReceiptReaderProvider', () {
    test('rien tant que le moteur reste sur l\'appareil', () async {
      final container = await containerOf(
        GeminiNanoStatus.downloadable,
        apiKey: 'AIza-cle',
      );

      expect(await container.read(cloudReceiptReaderProvider.future), isNull);
    });

    test('rien tant qu\'aucune clé n\'est enregistrée', () async {
      await PreferencesService.setQuickAddEngineMode(QuickAddEngineMode.apiKey);
      final container = await containerOf(GeminiNanoStatus.downloadable);

      expect(await container.read(cloudReceiptReaderProvider.future), isNull);
    });

    test('un lecteur dès que la clé est là et le moteur choisi', () async {
      await PreferencesService.setQuickAddEngineMode(QuickAddEngineMode.apiKey);
      final container = await containerOf(
        GeminiNanoStatus.downloadable,
        apiKey: 'AIza-cle',
      );

      expect(
        await container.read(cloudReceiptReaderProvider.future),
        isNotNull,
      );
    });
  });
}
