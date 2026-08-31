import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/gemini_nano_channel.dart';
import 'package:mybudget/core/enums/gemini_nano_failure.dart';
import 'package:mybudget/core/enums/gemini_nano_preference.dart';
import 'package:mybudget/core/enums/gemini_nano_status.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/services/ai/gemini_nano_service.dart';
import 'package:mybudget/core/services/quick_add/gemini_nano_unavailable_engine.dart';
import 'package:mybudget/core/services/quick_add/prompt_quick_add_engine.dart';
import 'package:mybudget/core/services/quick_add/racing_quick_add_engine.dart';
import 'package:mybudget/ui/quick_add/quick_add_engine_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubService extends GeminiNanoService {
  _StubService(this.answer);

  final GeminiNanoStatus answer;

  @override
  Future<GeminiNanoStatus> status(
    GeminiNanoChannel channel,
    GeminiNanoPreference preference,
  ) async => answer;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerFor(
    QuickAddEngineMode mode, {
    GeminiNanoStatus nano = GeminiNanoStatus.available,
  }) async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.keyQuickAddEngineMode: mode.id,
    });
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    await PreferencesService.init();

    final container = ProviderContainer(
      overrides: [
        geminiNanoServiceProvider.overrideWithValue(_StubService(nano)),
        quickAddClassifierProvider.overrideWith(
          (ref) async => throw StateError('le modèle embarqué ne doit pas être chargé'),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('quickAddEngine', () {
    test('sert Gemini Nano sans charger le modèle embarqué', () async {
      final container = await containerFor(QuickAddEngineMode.geminiNano);

      final engine = await container.read(quickAddEngineProvider.future);

      expect(engine, isA<PromptQuickAddEngine>());
      expect(engine, isNot(isA<RacingQuickAddEngine>()));
    });

    test('refuse d\'analyser tant que le modèle n\'est pas installé', () async {
      final container = await containerFor(
        QuickAddEngineMode.geminiNano,
        nano: GeminiNanoStatus.downloadable,
      );

      final engine = await container.read(quickAddEngineProvider.future);

      expect(engine, isA<GeminiNanoUnavailableEngine>());
      expect(
        (engine as GeminiNanoUnavailableEngine).failure,
        GeminiNanoFailure.notInstalled,
      );
      expect(
        () => engine.classify('resto'),
        throwsA(isA<GeminiNanoException>()),
      );
    });

    test('ne lance aucune inférence sur un appareil non éligible', () async {
      final container = await containerFor(
        QuickAddEngineMode.geminiNano,
        nano: GeminiNanoStatus.unavailable,
      );

      final engine = await container.read(quickAddEngineProvider.future);

      expect(
        (engine as GeminiNanoUnavailableEngine).failure,
        GeminiNanoFailure.unavailable,
      );
    });

    test('laisse remonter l\'échec du modèle embarqué hors Gemini Nano', () {
      expect(
        () async {
          final container = await containerFor(QuickAddEngineMode.onDevice);
          await container.read(quickAddEngineProvider.future);
        },
        throwsStateError,
      );
    });
  });
}
