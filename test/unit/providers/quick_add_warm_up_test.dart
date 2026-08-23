import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_engine.dart';
import 'package:mybudget/ui/quick_add/quick_add_engine_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockQuickAddEngine extends Mock implements QuickAddEngine {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int engineLoads;

  Future<ProviderContainer> containerWith({
    required bool quickAddEnabled,
    Object? failure,
  }) async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.keyQuickAddEnabled: quickAddEnabled,
    });
    await PreferencesService.init();

    final container = ProviderContainer(
      overrides: [
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

  setUp(() => engineLoads = 0);

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
}
