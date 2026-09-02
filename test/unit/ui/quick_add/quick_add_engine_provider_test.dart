import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/ai/api_key_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/quick_add/quick_add_engine_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubKeyService implements ApiKeyService {
  const _StubKeyService({this.readFailure});

  final Object? readFailure;

  @override
  Future<String?> read(AiProvider provider) async {
    if (readFailure != null) throw readFailure!;
    return null;
  }

  @override
  Future<bool> has(AiProvider provider) async => false;

  @override
  Future<void> save(AiProvider provider, String rawKey) async {}

  @override
  Future<void> delete(AiProvider provider) async {}

  @override
  Future<void> migrateLegacyGeminiKey() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerOf(_StubKeyService keys) {
    final container = ProviderContainer(
      overrides: [apiKeyServiceProvider.overrideWithValue(keys)],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();
    await PreferencesService.setQuickAddEngineMode(QuickAddEngineMode.apiKey);
  });

  group('quickAddEngineProvider', () {
    test('sans clé enregistrée, le moteur distant se refuse', () async {
      final container = containerOf(const _StubKeyService());

      await expectLater(
        container.read(quickAddEngineProvider.future),
        throwsA(isA<QuickAddEngineUnavailableException>()),
      );
    });

    test('une clé illisible se dit, elle ne se contourne pas', () async {
      final container = containerOf(
        _StubKeyService(readFailure: StateError('coffre verrouillé')),
      );

      await expectLater(
        container.read(quickAddEngineProvider.future),
        throwsA(isA<QuickAddEngineUnavailableException>()),
      );
    });
  });
}
