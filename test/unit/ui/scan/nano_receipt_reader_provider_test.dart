import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/enums/gemini_nano_channel.dart';
import 'package:mybudget/core/enums/gemini_nano_preference.dart';
import 'package:mybudget/core/enums/gemini_nano_status.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/ai/gemini_nano_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/scan/scan_provider.dart';
import 'package:mybudget/ui/settings/gemini_nano_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<ProviderContainer> containerOf(GeminiNanoStatus status) async {
    final container = ProviderContainer(
      overrides: [
        geminiNanoServiceProvider.overrideWithValue(_StubService(status)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(geminiNanoStatusProvider.future);
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

    test('couper le réglage retire le lecteur', () async {
      await PreferencesService.setGeminiNanoScanEnabled(true);
      final container = await containerOf(GeminiNanoStatus.available);

      await container.read(geminiNanoScanProvider.notifier).setEnabled(false);

      expect(container.read(nanoReceiptReaderProvider), isNull);
    });
  });
}
