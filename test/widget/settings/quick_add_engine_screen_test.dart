import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/constants/cloud_engine_availability.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/services/ai/api_key_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/settings/screens/gemini_cloud_screen.dart';
import 'package:mybudget/ui/settings/screens/quick_add_engine_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: FrostedTheme.light(seedColor: const Color(0xFF2A55D3)),
          home: const QuickAddEngineScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    await PreferencesService.init();
  });

  group('QuickAddEngineScreen', () {
    testWidgets('ne propose que les deux moteurs câblés', (tester) async {
      await pumpScreen(tester);

      expect(find.text(QuickAddEngineMode.onDevice.label), findsOneWidget);
      expect(find.text('Clé API personnelle'), findsOneWidget);
      expect(find.text('Gemini Nano'), findsNothing);
    });

    testWidgets('signale le moteur embarqué comme recommandé', (tester) async {
      await pumpScreen(tester);

      expect(find.text(recommendedEngineLabel), findsOneWidget);
    });

    testWidgets('annonce le cloud comme indisponible', (tester) async {
      await pumpScreen(tester);

      expect(
        find.text(cloudQuickAddEngineUnavailableNotice),
        findsOneWidget,
      );
    });

    testWidgets('le cloud ne repond plus au toucher', (tester) async {
      await ApiKeyService().save(AiProvider.gemini, 'AIzaStored');

      await pumpScreen(tester);
      await tester.tap(find.text('Clé API personnelle'));
      await tester.pumpAndSettle();

      expect(find.byType(GeminiCloudScreen), findsNothing);
      expect(
        find.text('Ce qui sera envoyé à ${AiProvider.gemini.label}'),
        findsNothing,
      );
      expect(
        PreferencesService.getQuickAddEngineMode(),
        QuickAddEngineMode.onDevice,
      );
    });

    testWidgets('ne promet plus de repli sur le modèle embarqué', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.textContaining('secours'), findsNothing);
    });

    testWidgets('retient le modèle embarqué', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text(QuickAddEngineMode.onDevice.label));
      await tester.pumpAndSettle();

      expect(
        PreferencesService.getQuickAddEngineMode(),
        QuickAddEngineMode.onDevice,
      );
    });

    testWidgets('ouvre la page Gemini cloud quand aucune clé n\'est enregistrée', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Clé API personnelle'));
      await tester.pumpAndSettle();

      expect(find.byType(GeminiCloudScreen), findsOneWidget);
      expect(
        PreferencesService.getQuickAddEngineMode(),
        QuickAddEngineMode.onDevice,
      );
    }, skip: !isCloudQuickAddEngineAvailable);

    testWidgets('demande le consentement avant de repasser au cloud', (
      tester,
    ) async {
      await ApiKeyService().save(AiProvider.gemini, 'AIzaStored');

      await pumpScreen(tester);
      await tester.tap(find.text('Clé API personnelle'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ce qui sera envoyé à ${AiProvider.gemini.label}'),
        findsOneWidget,
      );
      expect(
        PreferencesService.getQuickAddEngineMode(),
        QuickAddEngineMode.onDevice,
      );
    }, skip: !isCloudQuickAddEngineAvailable);

    testWidgets('un consentement accordé bascule sur le cloud', (tester) async {
      await ApiKeyService().save(AiProvider.gemini, 'AIzaStored');

      await pumpScreen(tester);
      await tester.tap(find.text('Clé API personnelle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activer'));
      await tester.pumpAndSettle();

      expect(
        PreferencesService.getQuickAddEngineMode(),
        QuickAddEngineMode.apiKey,
      );
    }, skip: !isCloudQuickAddEngineAvailable);

    testWidgets('un consentement refusé laisse le moteur embarqué', (
      tester,
    ) async {
      await ApiKeyService().save(AiProvider.gemini, 'AIzaStored');

      await pumpScreen(tester);
      await tester.tap(find.text('Clé API personnelle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(
        PreferencesService.getQuickAddEngineMode(),
        QuickAddEngineMode.onDevice,
      );
    }, skip: !isCloudQuickAddEngineAvailable);
  });
}
