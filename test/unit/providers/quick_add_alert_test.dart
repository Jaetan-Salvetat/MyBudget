import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/enums/gemini_nano_failure.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';
import 'package:mybudget/core/services/quick_add/quick_add_engine.dart';
import 'package:mybudget/ui/quick_add/quick_add_alert_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_engine_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingEngine implements QuickAddEngine {
  _FailingEngine(this.failure);

  final Object failure;

  @override
  Future<QuickAddClassification> classify(String input) async => throw failure;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerWith({
    required Object failure,
    required QuickAddEngineMode mode,
  }) async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.keyQuickAddEngineMode: mode.id,
    });
    await PreferencesService.init();

    final container = ProviderContainer(
      overrides: [
        quickAddEngineProvider.overrideWith((ref) async =>
            _FailingEngine(failure)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> analyze(ProviderContainer container) async {
    container.listen(quickAddProvider, (_, _) {}, fireImmediately: true);
    container.read(quickAddProvider.notifier).onInputChanged('resto italien');
    await Future<void>.delayed(QuickAddNotifier.analysisDebounce * 3);
  }

  group('échec du moteur Gemini Nano', () {
    test('remonte le message de la panne pour le toast', () async {
      final container = await containerWith(
        failure: const GeminiNanoException(GeminiNanoFailure.quotaExceeded),
        mode: QuickAddEngineMode.geminiNano,
      );

      await analyze(container);

      expect(
        container.read(quickAddAlertProvider)?.message,
        GeminiNanoFailure.quotaExceeded.message,
      );
    });

    test('laisse le brouillon sans message en ligne', () async {
      final container = await containerWith(
        failure: const GeminiNanoException(GeminiNanoFailure.quotaExceeded),
        mode: QuickAddEngineMode.geminiNano,
      );

      await analyze(container);

      expect(container.read(quickAddProvider).analysisError, isNull);
    });

    test('traite une réponse inexploitable comme une panne du moteur', () async {
      final container = await containerWith(
        failure: const AiRequestException(AiRequestFailure.malformedResponse),
        mode: QuickAddEngineMode.geminiNano,
      );

      await analyze(container);

      expect(
        container.read(quickAddAlertProvider)?.message,
        GeminiNanoFailure.malformedResponse.message,
      );
    });
  });

  group('échec du moteur embarqué', () {
    test('garde le message en ligne et ne lève aucun toast', () async {
      final container = await containerWith(
        failure: StateError('modèle absent'),
        mode: QuickAddEngineMode.onDevice,
      );

      await analyze(container);

      expect(container.read(quickAddAlertProvider), isNull);
      expect(
        container.read(quickAddProvider).analysisError,
        QuickAddNotifier.unreadInputMessage,
      );
    });

    test('ne toaste pas une panne réseau hors Gemini Nano', () async {
      final container = await containerWith(
        failure: const AiRequestException(AiRequestFailure.offline),
        mode: QuickAddEngineMode.apiKey,
      );

      await analyze(container);

      expect(container.read(quickAddAlertProvider), isNull);
    });
  });
}
