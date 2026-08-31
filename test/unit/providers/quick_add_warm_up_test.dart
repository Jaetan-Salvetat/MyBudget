import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/gemini_nano_status.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/ai/gemini_nano_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_engine.dart';
import 'package:mybudget/ui/quick_add/quick_add_engine_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockQuickAddEngine extends Mock implements QuickAddEngine {}

class _CountingNanoService extends GeminiNanoService {
  int warmUps = 0;

  @override
  Future<GeminiNanoStatus> status() async => GeminiNanoStatus.available;

  @override
  Future<void> warmUp() async => warmUps++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int engineLoads;

  late _CountingNanoService nano;

  Future<ProviderContainer> containerWith({
    required bool quickAddEnabled,
    Object? failure,
    QuickAddEngineMode mode = QuickAddEngineMode.onDevice,
  }) async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.keyQuickAddEnabled: quickAddEnabled,
      PreferencesService.keyQuickAddEngineMode: mode.id,
    });
    await PreferencesService.init();

    final container = ProviderContainer(
      overrides: [
        geminiNanoServiceProvider.overrideWithValue(nano),
        quickAddEngineProvider.overrideWith((ref) async {
          engineLoads++;
          if (failure != null) throw failure;
          return MockQuickAddEngine();
        }),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    engineLoads = 0;
    nano = _CountingNanoService();
  });

  group('quickAddWarmUp', () {
    test('charge le moteur quand l ajout rapide est actif', () async {
      final container = await containerWith(quickAddEnabled: true);

      await container.read(quickAddWarmUpProvider.future);

      expect(engineLoads, 1);
    });

    test('ne charge rien quand l ajout rapide est coupe', () async {
      final container = await containerWith(quickAddEnabled: false);

      await container.read(quickAddWarmUpProvider.future);

      expect(engineLoads, 0);
    });

    test('ne propage pas l echec du moteur', () async {
      final container = await containerWith(
        quickAddEnabled: true,
        failure: StateError('modele absent'),
      );

      await expectLater(container.read(quickAddWarmUpProvider.future), completes);
    });

    test('ne recharge pas le moteur a chaque lecture', () async {
      final container = await containerWith(quickAddEnabled: true);

      await container.read(quickAddWarmUpProvider.future);
      await container.read(quickAddWarmUpProvider.future);

      expect(engineLoads, 1);
    });
  });

  group('prechauffage Gemini Nano', () {
    test('reveille le modele natif quand il est selectionne', () async {
      final container = await containerWith(
        quickAddEnabled: true,
        mode: QuickAddEngineMode.geminiNano,
      );

      await container.read(quickAddWarmUpProvider.future);

      expect(nano.warmUps, 1);
    });

    test('ne touche pas au natif sur un autre moteur', () async {
      final container = await containerWith(
        quickAddEnabled: true,
        mode: QuickAddEngineMode.onDevice,
      );

      await container.read(quickAddWarmUpProvider.future);

      expect(nano.warmUps, 0);
    });
  });
}
