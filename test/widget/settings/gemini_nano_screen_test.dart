import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/gemini_nano_failure.dart';
import 'package:mybudget/core/enums/gemini_nano_status.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/models/gemini_nano_download.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/ai/gemini_nano_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/settings/screens/gemini_nano_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubService extends GeminiNanoService {
  _StubService(this.answer, this.steps);

  final GeminiNanoStatus answer;
  final StreamController<GeminiNanoDownload> steps;

  int downloads = 0;

  @override
  Future<GeminiNanoStatus> status() async => answer;

  @override
  Stream<GeminiNanoDownload> download() {
    downloads++;
    return steps.stream;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<GeminiNanoDownload> steps;
  late _StubService service;

  Future<void> pumpScreen(WidgetTester tester, GeminiNanoStatus status) async {
    service = _StubService(status, steps);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [geminiNanoServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          theme: FrostedTheme.light(seedColor: const Color(0xFF2A55D3)),
          home: const GeminiNanoScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();
    steps = StreamController<GeminiNanoDownload>.broadcast();
  });

  tearDown(() => steps.close());

  group('GeminiNanoScreen', () {
    testWidgets('annonce un modèle prêt', (tester) async {
      await pumpScreen(tester, GeminiNanoStatus.available);

      expect(find.text('Le modèle est installé et prêt.'), findsOneWidget);
      expect(find.text('Télécharger le modèle'), findsNothing);
    });

    testWidgets('explique un appareil non éligible sans rien proposer', (
      tester,
    ) async {
      await pumpScreen(tester, GeminiNanoStatus.unavailable);

      expect(find.textContaining('ne propose pas Gemini Nano'), findsOneWidget);
      expect(find.text('Télécharger le modèle'), findsNothing);
    });

    testWidgets('permet de suivre un téléchargement lancé par le système', (
      tester,
    ) async {
      await pumpScreen(tester, GeminiNanoStatus.downloading);

      expect(find.textContaining('télécharge déjà le modèle'), findsOneWidget);

      await tester.tap(find.text('Suivre le téléchargement'));
      await tester.pump();

      expect(service.downloads, 1);
    });

    testWidgets('bascule l\'ajout rapide sur Nano une fois installé', (
      tester,
    ) async {
      await pumpScreen(tester, GeminiNanoStatus.downloadable);

      await tester.tap(find.text('Télécharger le modèle'));
      await tester.pump();

      steps.add(const GeminiNanoDownloadCompleted());
      await tester.pumpAndSettle();

      expect(
        PreferencesService.getQuickAddEngineMode(),
        QuickAddEngineMode.geminiNano,
      );
      expect(find.text('Le modèle est installé et prêt.'), findsOneWidget);
    });

    testWidgets('affiche l\'avancement en pourcentage une fois lancé', (
      tester,
    ) async {
      await pumpScreen(tester, GeminiNanoStatus.downloadable);

      await tester.tap(find.text('Télécharger le modèle'));
      await tester.pump();

      expect(service.downloads, 1);
      expect(find.text('Téléchargement en cours…'), findsOneWidget);

      steps.add(
        const GeminiNanoDownloadProgress(
          downloadedBytes: 64 * 1024 * 1024,
          totalBytes: 256 * 1024 * 1024,
        ),
      );
      await tester.pump();

      expect(find.text('25 % · 64 Mo sur 256 Mo'), findsOneWidget);
      expect(
        tester.widget<FrostedLinearProgress>(
          find.byType(FrostedLinearProgress),
        ).value,
        0.25,
      );
    });

    testWidgets('propose de réessayer après un échec récupérable', (
      tester,
    ) async {
      await pumpScreen(tester, GeminiNanoStatus.downloadable);

      await tester.tap(find.text('Télécharger le modèle'));
      await tester.pump();

      steps.add(
        const GeminiNanoDownloadFailed(GeminiNanoFailure.outOfSpace),
      );
      await tester.pump();

      expect(find.text(GeminiNanoFailure.outOfSpace.message), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('ne propose pas de réessayer un échec définitif', (
      tester,
    ) async {
      await pumpScreen(tester, GeminiNanoStatus.downloadable);

      await tester.tap(find.text('Télécharger le modèle'));
      await tester.pump();

      steps.add(
        const GeminiNanoDownloadFailed(GeminiNanoFailure.unavailable),
      );
      await tester.pump();

      expect(find.text('Réessayer'), findsNothing);
    });
  });
}
