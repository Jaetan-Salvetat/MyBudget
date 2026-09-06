import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/data/provider/ai_settings_provider.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/service/ai/api_key_service.dart';
import 'package:mybudget/data/service/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  Future<void> initPreferences(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    await PreferencesService.init();
  }

  tearDown(() => container.dispose());

  group('QuickAddEnabledNotifier', () {
    test('is enabled by default when no preference is stored', () async {
      await initPreferences({});
      container = ProviderContainer();

      expect(container.read(quickAddEnabledProvider), isTrue);
    });

    test('reads the stored preference when it is disabled', () async {
      await initPreferences({PreferencesService.keyQuickAddEnabled: false});
      container = ProviderContainer();

      expect(container.read(quickAddEnabledProvider), isFalse);
    });

    test('setEnabled(false) updates the state', () async {
      await initPreferences({});
      container = ProviderContainer();

      await container.read(quickAddEnabledProvider.notifier).setEnabled(false);

      expect(container.read(quickAddEnabledProvider), isFalse);
    });

    test('setEnabled persists the value across containers', () async {
      await initPreferences({});
      container = ProviderContainer();

      await container.read(quickAddEnabledProvider.notifier).setEnabled(false);
      container.dispose();
      container = ProviderContainer();

      expect(container.read(quickAddEnabledProvider), isFalse);
    });

    test('setEnabled(true) re-enables a disabled quick add', () async {
      await initPreferences({PreferencesService.keyQuickAddEnabled: false});
      container = ProviderContainer();

      await container.read(quickAddEnabledProvider.notifier).setEnabled(true);

      expect(container.read(quickAddEnabledProvider), isTrue);
      expect(PreferencesService.isQuickAddEnabled(), isTrue);
    });
  });

  group('QuickAddEngineModeNotifier', () {
    test('stays on device until something says otherwise', () async {
      await initPreferences({});
      container = ProviderContainer();

      expect(
        container.read(quickAddEngineModeProvider),
        QuickAddEngineMode.onDevice,
      );
    });

    test('persists the chosen mode across containers', () async {
      await initPreferences({});
      container = ProviderContainer();

      await container
          .read(quickAddEngineModeProvider.notifier)
          .setMode(QuickAddEngineMode.apiKey);
      container.dispose();
      container = ProviderContainer();

      expect(
        container.read(quickAddEngineModeProvider),
        QuickAddEngineMode.apiKey,
      );
    });

    test('falls back on device when the stored value is unknown', () async {
      await initPreferences({
        PreferencesService.keyQuickAddEngineMode: 'martien',
      });
      container = ProviderContainer();

      expect(
        container.read(quickAddEngineModeProvider),
        QuickAddEngineMode.onDevice,
      );
    });
  });

  group('hasStoredApiKey', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues(<String, String>{}));

    test('is false while the keychain holds nothing', () async {
      await initPreferences({});
      container = ProviderContainer();

      expect(await container.read(hasStoredApiKeyProvider.future), isFalse);
    });

    test('is true once a key is stored for the chosen service', () async {
      await initPreferences({});
      await ApiKeyService().save(AiProvider.gemini, 'AIzaStored');
      container = ProviderContainer();

      expect(await container.read(hasStoredApiKeyProvider.future), isTrue);
    });
  });

  group('quickAddEngine composition', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues(<String, String>{}));

    test('reuses the shared key service', () async {
      await initPreferences({});
      container = ProviderContainer();

      expect(container.read(apiKeyServiceProvider), isA<ApiKeyService>());
    });
  });

  group('quickAddUsesRemote', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues(<String, String>{}));

    test('is false while the engine stays on device', () async {
      await initPreferences({});
      await ApiKeyService().save(AiProvider.gemini, 'AIzaStored');
      container = ProviderContainer();
      await container.read(hasStoredApiKeyProvider.future);

      expect(container.read(quickAddUsesRemoteProvider), isFalse);
    });

    test('is false when the mode is set but no key is stored', () async {
      await initPreferences({
        PreferencesService.keyQuickAddEngineMode: QuickAddEngineMode.apiKey.id,
      });
      container = ProviderContainer();
      await container.read(hasStoredApiKeyProvider.future);

      expect(container.read(quickAddUsesRemoteProvider), isFalse);
    });

    test('is true once the mode and the key are both in place', () async {
      await initPreferences({
        PreferencesService.keyQuickAddEngineMode: QuickAddEngineMode.apiKey.id,
      });
      await ApiKeyService().save(AiProvider.gemini, 'AIzaStored');
      container = ProviderContainer();
      await container.read(hasStoredApiKeyProvider.future);

      expect(container.read(quickAddUsesRemoteProvider), isTrue);
    });
  });

  group('SelectedAiModelNotifier', () {
    test('falls back to the default model when nothing is stored', () async {
      await initPreferences({});
      container = ProviderContainer();

      expect(container.read(selectedAiModelProvider), AiModel.fallback);
    });

    test('reads the stored model', () async {
      await initPreferences({
        PreferencesService.keyAiModel: AiModel.flash35.id,
      });
      container = ProviderContainer();

      expect(container.read(selectedAiModelProvider), AiModel.flash35);
    });

    test('select updates the state', () async {
      await initPreferences({});
      container = ProviderContainer();

      await container
          .read(selectedAiModelProvider.notifier)
          .select(AiModel.flash37);

      expect(container.read(selectedAiModelProvider), AiModel.flash37);
    });

    test('select persists the model across containers', () async {
      await initPreferences({});
      container = ProviderContainer();

      await container
          .read(selectedAiModelProvider.notifier)
          .select(AiModel.flash36);
      container.dispose();
      container = ProviderContainer();

      expect(container.read(selectedAiModelProvider), AiModel.flash36);
    });
  });
}
