import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/services/ai/api_key_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/settings/widgets/sections/ai_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSection(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: FrostedTheme.light(seedColor: const Color(0xFF2A55D3)),
          home: const Scaffold(body: AiSection()),
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

  group('AiSection', () {
    testWidgets('hides the key entry while nothing uses a key', (tester) async {
      await pumpSection(tester);

      expect(find.text('Ajout rapide'), findsOneWidget);
      expect(find.text('Moteur d\'analyse'), findsOneWidget);
      expect(find.text('Clé API'), findsNothing);
      expect(find.text('Modèle'), findsNothing);
    });

    testWidgets('keeps the key entry hidden while the engine is local', (
      tester,
    ) async {
      await ApiKeyService().save(AiProvider.gemini, 'AIzaStored');

      await pumpSection(tester);

      expect(find.text('Clé API'), findsNothing);
      expect(find.text('Modèle'), findsNothing);
    });

    testWidgets('shows the key and the model once the engine is remote', (
      tester,
    ) async {
      await PreferencesService.setQuickAddEngineMode(
        QuickAddEngineMode.apiKey,
      );
      await ApiKeyService().save(AiProvider.gemini, 'AIzaStored');

      await pumpSection(tester);

      expect(find.text('Clé API'), findsOneWidget);
      expect(find.text('Enregistrée'), findsOneWidget);
      expect(find.text('Modèle'), findsOneWidget);
      expect(find.text(AiModel.fallback.label), findsOneWidget);
    });

    testWidgets('names the selected model under the model entry', (
      tester,
    ) async {
      await PreferencesService.setQuickAddEngineMode(
        QuickAddEngineMode.apiKey,
      );
      await PreferencesService.setAiModel(AiModel.flash37);

      await pumpSection(tester);

      expect(find.text(AiModel.flash37.label), findsOneWidget);
    });

    testWidgets('hides the key and the model when quick add is off', (
      tester,
    ) async {
      await PreferencesService.setQuickAddEngineMode(
        QuickAddEngineMode.apiKey,
      );
      await PreferencesService.setQuickAddEnabled(false);

      await pumpSection(tester);

      expect(find.text('Clé API'), findsNothing);
      expect(find.text('Modèle'), findsNothing);
    });

    testWidgets('hides the engine entry when quick add is off', (tester) async {
      await PreferencesService.setQuickAddEnabled(false);

      await pumpSection(tester);

      expect(find.text('Moteur d\'analyse'), findsNothing);
    });

    testWidgets('drops the on-device promise once the engine changed', (
      tester,
    ) async {
      await PreferencesService.setQuickAddEngineMode(
        QuickAddEngineMode.apiKey,
      );

      await pumpSection(tester);

      expect(
        find.text('Analyse une saisie en langage naturel'),
        findsOneWidget,
      );
      expect(find.text('Clé personnelle'), findsOneWidget);
    });
  });
}
