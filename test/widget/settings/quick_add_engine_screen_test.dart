import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/gemini_nano_channel.dart';
import 'package:mybudget/core/enums/gemini_nano_preference.dart';
import 'package:mybudget/core/enums/gemini_nano_status.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/models/gemini_nano_download.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/ai/gemini_nano_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/settings/screens/gemini_nano_screen.dart';
import 'package:mybudget/ui/settings/screens/quick_add_engine_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubService extends GeminiNanoService {
  _StubService(this.answer);

  final GeminiNanoStatus answer;

  @override
  Future<GeminiNanoStatus> status(
    GeminiNanoChannel channel,
    GeminiNanoPreference preference,
  ) async => answer;

  @override
  Stream<GeminiNanoDownload> download(
    GeminiNanoChannel channel,
    GeminiNanoPreference preference,
  ) => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpScreen(WidgetTester tester, GeminiNanoStatus status) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          geminiNanoServiceProvider.overrideWithValue(_StubService(status)),
        ],
        child: MaterialApp(
          theme: FrostedTheme.light(seedColor: const Color(0xFF2A55D3)),
          home: const QuickAddEngineScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  FrostedRadio<QuickAddEngineMode> radioOf(QuickAddEngineMode mode) {
    return find
        .byWidgetPredicate(
          (widget) =>
              widget is FrostedRadio<QuickAddEngineMode> && widget.value == mode,
        )
        .evaluate()
        .single
        .widget as FrostedRadio<QuickAddEngineMode>;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    await PreferencesService.init();
  });

  group('QuickAddEngineScreen', () {
    testWidgets('propose les trois moteurs, Gemini Nano recommandé', (
      tester,
    ) async {
      await pumpScreen(tester, GeminiNanoStatus.available);

      expect(find.text(QuickAddEngineMode.geminiNano.label), findsOneWidget);
      expect(find.text(QuickAddEngineMode.onDevice.label), findsOneWidget);
      expect(find.text('Clé API personnelle'), findsOneWidget);
      expect(
        find.text(QuickAddEngineScreen.recommendedLabel),
        findsOneWidget,
      );
    });

    testWidgets('désactive Gemini Nano quand l\'appareil ne suit pas', (
      tester,
    ) async {
      await pumpScreen(tester, GeminiNanoStatus.unavailable);

      expect(radioOf(QuickAddEngineMode.geminiNano).onChanged, isNull);
      expect(
        find.text('Cet appareil ne propose pas Gemini Nano.'),
        findsOneWidget,
      );

      await tester.tap(find.text(QuickAddEngineMode.geminiNano.label));
      await tester.pumpAndSettle();

      expect(
        PreferencesService.getQuickAddEngineMode(),
        QuickAddEngineMode.onDevice,
      );
    });

    testWidgets('sélectionne Gemini Nano quand le modèle est prêt', (
      tester,
    ) async {
      await pumpScreen(tester, GeminiNanoStatus.available);

      await tester.tap(find.text(QuickAddEngineMode.geminiNano.label));
      await tester.pumpAndSettle();

      expect(
        PreferencesService.getQuickAddEngineMode(),
        QuickAddEngineMode.geminiNano,
      );
    });

    testWidgets('ouvre la gestion du modèle tant qu\'il n\'est pas installé', (
      tester,
    ) async {
      await pumpScreen(tester, GeminiNanoStatus.downloadable);

      await tester.tap(find.text(QuickAddEngineMode.geminiNano.label));
      await tester.pumpAndSettle();

      expect(find.byType(GeminiNanoScreen), findsOneWidget);
      expect(
        PreferencesService.getQuickAddEngineMode(),
        QuickAddEngineMode.onDevice,
      );
    });
  });
}
