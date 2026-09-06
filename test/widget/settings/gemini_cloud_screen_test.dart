import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/core/services/ai/api_key_service.dart';
import 'package:mybudget/core/services/ai/api_key_verifier.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:mybudget/ui/settings/screens/gemini_cloud_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubChatClient implements AiChatClient {
  const _StubChatClient(this.error);

  final Object? error;

  @override
  Future<String> complete({
    required String prompt,
    required String schemaName,
    required Map<String, dynamic> schema,
    AiImageAttachment? image,
  }) async {
    final Object? failure = error;
    if (failure != null) throw failure;
    return '{"ok":true}';
  }

  @override
  void close() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String validKey = 'AIzaSyA01234567890123456789012345678901';

  late ProviderContainer container;

  Future<void> pumpScreen(WidgetTester tester, {Object? verifierError}) async {
    tester.view.physicalSize = const Size(440, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    container = ProviderContainer(
      overrides: [
        apiKeyVerifierProvider.overrideWithValue(
          ApiKeyVerifier(
            clientFactory: (_, _, _) => _StubChatClient(verifierError),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: FrostedTheme.light(seedColor: const Color(0xFF2A55D3)),
          home: const GeminiCloudScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submitKey(
    WidgetTester tester,
    String key, {
    bool consent = true,
  }) async {
    await tester.enterText(find.byType(FrostedTextField), key);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vérifier et activer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(consent ? 'Activer' : 'Annuler'));
    await tester.pumpAndSettle();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    await PreferencesService.init();
  });

  group('GeminiCloudScreen', () {
    testWidgets('gathers the key and the model on a single screen', (
      tester,
    ) async {
      await ApiKeyService().save(AiProvider.gemini, validKey);

      await pumpScreen(tester);

      expect(find.text('Vérifier et activer'), findsOneWidget);
      expect(find.text('Modèle'), findsOneWidget);
      for (final AiModel model in AiModel.forProvider(AiProvider.gemini)) {
        expect(find.text(model.label), findsOneWidget);
      }
    });

    testWidgets('hides the model choice while no key is stored', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('Modèle'), findsNothing);
      expect(find.text(AiModel.fallback.label), findsNothing);
      expect(find.text('Supprimer la clé'), findsNothing);
    });

    testWidgets('tapping a model selects it and persists it', (tester) async {
      await ApiKeyService().save(AiProvider.gemini, validKey);

      await pumpScreen(tester);
      await tester.tap(find.text(AiModel.flash37.label));
      await tester.pumpAndSettle();

      expect(container.read(selectedAiModelProvider), AiModel.flash37);
      expect(PreferencesService.getAiModel(), AiModel.flash37);
    });

    testWidgets('a verified key stays on the screen and reveals the model', (
      tester,
    ) async {
      await pumpScreen(tester);
      await submitKey(tester, validKey);

      expect(find.byType(GeminiCloudScreen), findsOneWidget);
      expect(find.text('Modèle'), findsOneWidget);
      expect(find.text('Clé enregistrée.'), findsOneWidget);
      expect(
        PreferencesService.getQuickAddEngineMode(),
        QuickAddEngineMode.apiKey,
      );
    });

    testWidgets('asks for cloud consent again on every verification', (
      tester,
    ) async {
      await pumpScreen(tester);
      await submitKey(tester, validKey);

      expect(
        PreferencesService.getQuickAddEngineMode(),
        QuickAddEngineMode.apiKey,
      );

      await tester.enterText(find.byType(FrostedTextField), validKey);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vérifier et activer'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ce qui sera envoyé à ${AiProvider.gemini.label}'),
        findsOneWidget,
      );
    });

    testWidgets('a refused consent leaves the engine untouched', (
      tester,
    ) async {
      await pumpScreen(tester);
      await submitKey(tester, validKey, consent: false);

      expect(
        PreferencesService.getQuickAddEngineMode(),
        QuickAddEngineMode.onDevice,
      );
      expect(find.text('Modèle'), findsNothing);
    });

    testWidgets('a refused key keeps the model choice away', (tester) async {
      await pumpScreen(tester);
      await submitKey(tester, 'sk-proj-not-a-google-key');

      expect(find.text('Modèle'), findsNothing);
      expect(
        PreferencesService.getQuickAddEngineMode(),
        QuickAddEngineMode.onDevice,
      );
    });

    testWidgets('warns when the accepted key has no quota left', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        verifierError: const AiRequestException(AiRequestFailure.quotaExceeded),
      );
      await submitKey(tester, validKey);

      expect(find.text(GeminiCloudScreen.quotaNotice), findsOneWidget);
      expect(find.text('Modèle'), findsOneWidget);
    });

    testWidgets('deleting the key falls back to the on-device engine', (
      tester,
    ) async {
      await ApiKeyService().save(AiProvider.gemini, validKey);
      await PreferencesService.setQuickAddEngineMode(QuickAddEngineMode.apiKey);

      await pumpScreen(tester);
      await tester.tap(find.text('Supprimer la clé'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(await ApiKeyService().has(AiProvider.gemini), isFalse);
      expect(
        PreferencesService.getQuickAddEngineMode(),
        QuickAddEngineMode.onDevice,
      );
      expect(find.text('Modèle'), findsNothing);
    });
  });
}
