import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/quick_add/quick_add_engine_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerFor(QuickAddEngineMode mode) async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.keyQuickAddEngineMode: mode.id,
    });
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    await PreferencesService.init();

    final container = ProviderContainer(
      overrides: [
        quickAddClassifierProvider.overrideWith(
          (ref) async => throw StateError('modèle embarqué indisponible'),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('quickAddEngine', () {
    test('laisse remonter l\'échec du modèle embarqué', () {
      expect(
        () async {
          final container = await containerFor(QuickAddEngineMode.onDevice);
          await container.read(quickAddEngineProvider.future);
        },
        throwsStateError,
      );
    });

    test('retombe sur le modèle embarqué sans clé enregistrée', () {
      expect(
        () async {
          final container = await containerFor(QuickAddEngineMode.apiKey);
          await container.read(quickAddEngineProvider.future);
        },
        throwsStateError,
      );
    });
  });
}
