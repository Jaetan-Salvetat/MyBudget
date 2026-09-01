import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/gemini_nano_channel.dart';
import 'package:mybudget/core/enums/gemini_nano_failure.dart';
import 'package:mybudget/core/enums/gemini_nano_preference.dart';
import 'package:mybudget/core/enums/gemini_nano_status.dart';
import 'package:mybudget/core/models/gemini_nano_download.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/ai/gemini_nano_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/settings/gemini_nano_provider.dart';
import 'package:mybudget/ui/settings/screens/gemini_nano_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubService extends GeminiNanoService {
  _StubService(this.answer, this.steps);

  final GeminiNanoStatus answer;
  final StreamController<GeminiNanoDownload> steps;

  int downloads = 0;
  GeminiNanoPreference? askedPreference;

  @override
  Future<GeminiNanoStatus> status(
    GeminiNanoChannel channel,
    GeminiNanoPreference preference,
  ) async => answer;

  @override
  Future<String?> modelName(
    GeminiNanoChannel channel,
    GeminiNanoPreference preference,
  ) async => 'nano-v3-full';

  @override
  Stream<GeminiNanoDownload> download(
    GeminiNanoChannel channel,
    GeminiNanoPreference preference,
  ) {
    downloads++;
    askedPreference = preference;
    return steps.stream;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<GeminiNanoDownload> steps;
  late _StubService service;
  late ProviderContainer container;

  Future<void> pumpScreen(WidgetTester tester, GeminiNanoStatus status) async {
    service = _StubService(status, steps);
    final scope = ProviderScope(
      overrides: [geminiNanoServiceProvider.overrideWithValue(service)],
      child: MaterialApp(
        theme: FrostedTheme.light(seedColor: const Color(0xFF2A55D3)),
        home: const GeminiNanoScreen(),
      ),
    );
    await tester.pumpWidget(scope);
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(GeminiNanoScreen)),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();
    steps = StreamController<GeminiNanoDownload>.broadcast();
  });

  tearDown(() => steps.close());

  group('GeminiNanoScreen', () {
    testWidgets('un modèle absent se propose au téléchargement', (tester) async {
      await pumpScreen(tester, GeminiNanoStatus.downloadable);

      expect(find.text('Télécharger le modèle complet'), findsOneWidget);
      expect(find.text(GeminiNanoScreen.scanTitle), findsNothing);
    });

    testWidgets('le téléchargement demande bien le modèle complet',
        (tester) async {
      await pumpScreen(tester, GeminiNanoStatus.downloadable);

      await tester.tap(find.text('Télécharger le modèle complet'));
      await tester.pump();

      expect(service.downloads, 1);
      expect(service.askedPreference, GeminiNanoPreference.full);
    });

    testWidgets('la progression est affichée en pourcentage', (tester) async {
      await pumpScreen(tester, GeminiNanoStatus.downloadable);

      await tester.tap(find.text('Télécharger le modèle complet'));
      await tester.pump();
      steps.add(
        const GeminiNanoDownloadProgress(
          downloadedBytes: 512 * 1024 * 1024,
          totalBytes: 1024 * 1024 * 1024,
        ),
      );
      await tester.pump();

      expect(find.textContaining('50 %'), findsOneWidget);
    });

    testWidgets('un téléchargement terminé active la lecture des tickets',
        (tester) async {
      await pumpScreen(tester, GeminiNanoStatus.downloadable);

      await tester.tap(find.text('Télécharger le modèle complet'));
      await tester.pump();
      steps.add(const GeminiNanoDownloadCompleted());
      await tester.pumpAndSettle();

      expect(container.read(geminiNanoScanProvider), isTrue);
      expect(PreferencesService.isGeminiNanoScanEnabled(), isTrue);
    });

    testWidgets('un échec récupérable se rejoue', (tester) async {
      await pumpScreen(tester, GeminiNanoStatus.downloadable);

      await tester.tap(find.text('Télécharger le modèle complet'));
      await tester.pump();
      steps.add(
        const GeminiNanoDownloadFailed(GeminiNanoFailure.quotaExceeded),
      );
      await tester.pump();

      expect(find.text(GeminiNanoFailure.quotaExceeded.message), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      await tester.pump();

      expect(service.downloads, 2);
    });

    testWidgets('un échec définitif ne propose pas de réessayer',
        (tester) async {
      await pumpScreen(tester, GeminiNanoStatus.downloadable);

      await tester.tap(find.text('Télécharger le modèle complet'));
      await tester.pump();
      steps.add(
        const GeminiNanoDownloadFailed(GeminiNanoFailure.unavailable),
      );
      await tester.pump();

      expect(find.text('Réessayer'), findsNothing);
    });

    testWidgets('un modèle prêt offre le switch de lecture des tickets',
        (tester) async {
      await pumpScreen(tester, GeminiNanoStatus.available);

      expect(find.text(GeminiNanoScreen.scanTitle), findsOneWidget);
      expect(find.textContaining('nano-v3-full'), findsOneWidget);

      final before = tester.widget<FrostedSwitch>(find.byType(FrostedSwitch));
      expect(before.value, isFalse);

      await tester.tap(find.byType(FrostedSwitch));
      await tester.pumpAndSettle();

      expect(container.read(geminiNanoScanProvider), isTrue);
      expect(PreferencesService.isGeminiNanoScanEnabled(), isTrue);
    });

    testWidgets('un appareil incompatible le dit sans rien proposer',
        (tester) async {
      await pumpScreen(tester, GeminiNanoStatus.unavailable);

      expect(find.textContaining('ne propose pas Gemini Nano'), findsOneWidget);
      expect(find.byType(FrostedSwitch), findsNothing);
      expect(find.byType(FrostedButton), findsNothing);
    });
  });
}
