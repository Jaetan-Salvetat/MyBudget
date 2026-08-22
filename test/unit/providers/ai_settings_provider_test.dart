import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/ai/api_key_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
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

  group('QuickAddDegradationNotifier', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues(<String, String>{}));

    test('starts healthy', () async {
      await initPreferences({});
      container = ProviderContainer();

      expect(container.read(quickAddDegradationProvider), isFalse);
    });

    test('flips after enough failures', () async {
      await initPreferences({});
      container = ProviderContainer();
      final notifier = container.read(quickAddDegradationProvider.notifier);

      await notifier.reportFailure(AiRequestFailure.serviceUnavailable);
      await notifier.reportFailure(AiRequestFailure.serviceUnavailable);
      expect(container.read(quickAddDegradationProvider), isFalse);

      await notifier.reportFailure(AiRequestFailure.serviceUnavailable);
      expect(container.read(quickAddDegradationProvider), isTrue);
    });

    test('flips at once on a revoked key', () async {
      await initPreferences({});
      container = ProviderContainer();

      await container
          .read(quickAddDegradationProvider.notifier)
          .reportFailure(AiRequestFailure.invalidKey);

      expect(container.read(quickAddDegradationProvider), isTrue);
    });

    test('a success brings the remote engine back', () async {
      await initPreferences({});
      container = ProviderContainer();
      final notifier = container.read(quickAddDegradationProvider.notifier);

      await notifier.reportFailure(AiRequestFailure.invalidKey);
      await notifier.reportSuccess();

      expect(container.read(quickAddDegradationProvider), isFalse);
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
}
