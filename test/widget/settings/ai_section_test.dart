import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/enums/build_flavor.dart';
import 'package:mybudget/core/enums/gemini_nano_channel.dart';
import 'package:mybudget/core/constants/cloud_engine_availability.dart';
import 'package:mybudget/core/enums/gemini_nano_preference.dart';
import 'package:mybudget/core/enums/gemini_nano_status.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/ai/gemini_nano_service.dart';
import 'package:mybudget/core/services/ai/api_key_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/settings/widgets/sections/ai_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubNanoService extends GeminiNanoService {
  const _StubNanoService(this.answer);

  final GeminiNanoStatus answer;

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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSection(
    WidgetTester tester, {
    GeminiNanoStatus nano = GeminiNanoStatus.unavailable,
    BuildFlavor flavor = BuildFlavor.prod,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          geminiNanoServiceProvider.overrideWithValue(_StubNanoService(nano)),
          buildFlavorProvider.overrideWithValue(flavor),
        ],
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
    testWidgets('names the switch after what it actually replaces', (
      tester,
    ) async {
      await pumpSection(tester);

      expect(find.text('Saisie en langage naturel'), findsOneWidget);
      expect(find.text('Ajout rapide'), findsNothing);
      expect(
        find.text('Écrire « resto 25 » au lieu de remplir un formulaire'),
        findsOneWidget,
      );
    });

    testWidgets('hides the cloud entry while the engine is local', (
      tester,
    ) async {
      await ApiKeyService().save(AiProvider.gemini, 'AIzaStored');

      await pumpSection(tester);

      expect(find.text('Moteur d\'analyse'), findsOneWidget);
      expect(find.text('Gemini cloud'), findsNothing);
      expect(find.text('Clé API'), findsNothing);
      expect(find.text('Modèle'), findsNothing);
    });

    testWidgets('gathers the cloud settings behind a single entry', (
      tester,
    ) async {
      await PreferencesService.setQuickAddEngineMode(
        QuickAddEngineMode.apiKey,
      );
      await ApiKeyService().save(AiProvider.gemini, 'AIzaStored');

      await pumpSection(tester);

      expect(find.text('Gemini cloud'), findsOneWidget);
      expect(
        find.text('Clé enregistrée · ${AiModel.fallback.label}'),
        findsOneWidget,
      );
      expect(find.text('Clé API'), findsNothing);
      expect(find.text('Modèle'), findsNothing);
    }, skip: !isCloudQuickAddEngineAvailable);

    testWidgets('names the selected model under the cloud entry', (
      tester,
    ) async {
      await PreferencesService.setQuickAddEngineMode(
        QuickAddEngineMode.apiKey,
      );
      await PreferencesService.setAiModel(AiModel.flash37);
      await ApiKeyService().save(AiProvider.gemini, 'AIzaStored');

      await pumpSection(tester);

      expect(
        find.text('Clé enregistrée · ${AiModel.flash37.label}'),
        findsOneWidget,
      );
    }, skip: !isCloudQuickAddEngineAvailable);

    testWidgets('calls out a remote engine left without a key', (tester) async {
      await PreferencesService.setQuickAddEngineMode(
        QuickAddEngineMode.apiKey,
      );

      await pumpSection(tester);

      expect(find.text('Aucune clé enregistrée'), findsOneWidget);
    }, skip: !isCloudQuickAddEngineAvailable);

    testWidgets('keeps the engine reachable when the input switch is off', (
      tester,
    ) async {
      await PreferencesService.setQuickAddEnabled(false);
      await PreferencesService.setQuickAddEngineMode(
        QuickAddEngineMode.apiKey,
      );
      await ApiKeyService().save(AiProvider.gemini, 'AIzaStored');

      await pumpSection(tester);

      expect(find.text('Moteur d\'analyse'), findsOneWidget);
      expect(find.text('Gemini cloud'), findsOneWidget);
    }, skip: !isCloudQuickAddEngineAvailable);

    testWidgets('hides Gemini Nano on a device that does not offer it', (
      tester,
    ) async {
      await pumpSection(tester);

      expect(find.text('Gemini Nano'), findsNothing);
    });

    testWidgets('hides Gemini Nano while the engine runs in the cloud', (
      tester,
    ) async {
      await PreferencesService.setQuickAddEngineMode(
        QuickAddEngineMode.apiKey,
      );

      await pumpSection(tester, nano: GeminiNanoStatus.available);

      expect(find.text('Gemini Nano'), findsNothing);
      expect(find.text('Gemini cloud'), findsOneWidget);
    }, skip: !isCloudQuickAddEngineAvailable);

    testWidgets('offers Gemini Nano as soon as the model can be installed', (
      tester,
    ) async {
      await pumpSection(tester, nano: GeminiNanoStatus.downloadable);

      expect(find.text('Gemini Nano'), findsOneWidget);
      expect(find.text('Modèle pas encore installé'), findsOneWidget);
    });

    testWidgets('says Gemini Nano is idle until the scan uses it', (
      tester,
    ) async {
      await pumpSection(tester, nano: GeminiNanoStatus.available);

      expect(find.text('Installé, pas encore utilisé'), findsOneWidget);
    });

    testWidgets('drops the engine entry from the store build', (
      tester,
    ) async {
      await pumpSection(tester, flavor: BuildFlavor.store);

      expect(find.text('Moteur d\'analyse'), findsNothing);
    });

    testWidgets('keeps Gemini Nano in the store build on a device that '
        'offers it', (tester) async {
      await PreferencesService.setGeminiNanoScanEnabled(true);

      await pumpSection(
        tester,
        nano: GeminiNanoStatus.available,
        flavor: BuildFlavor.store,
      );

      expect(find.text('Gemini Nano'), findsOneWidget);
      expect(find.text('Moteur d\'analyse'), findsNothing);
      expect(find.text('Gemini cloud'), findsNothing);
    });

    testWidgets('hides Gemini Nano from the store build on a device that '
        'does not offer it', (tester) async {
      await pumpSection(tester, flavor: BuildFlavor.store);

      expect(find.text('Gemini Nano'), findsNothing);
    });

    testWidgets('keeps the natural input switch in the store build', (
      tester,
    ) async {
      await pumpSection(tester, flavor: BuildFlavor.store);

      final FrostedListTile tile = tester
          .widget<FrostedListSection>(find.byType(FrostedListSection))
          .tiles
          .single;

      expect(tile.title, AiSection.naturalInputTitle);
      expect(tile.trailing, isA<FrostedSwitch>());
    });

    testWidgets('says Gemini Nano reads receipts once turned on', (
      tester,
    ) async {
      await PreferencesService.setGeminiNanoScanEnabled(true);

      await pumpSection(tester, nano: GeminiNanoStatus.available);

      expect(find.text('Lit les tickets sur l\'appareil'), findsOneWidget);
    });

    testWidgets('keeps Gemini Nano reachable while the engine is local', (
      tester,
    ) async {
      await PreferencesService.setQuickAddEnabled(false);

      await pumpSection(tester, nano: GeminiNanoStatus.available);

      expect(find.text('Gemini Nano'), findsOneWidget);
      expect(find.text('Gemini cloud'), findsNothing);
    });

    testWidgets('reads the current engine under the engine entry', (
      tester,
    ) async {
      await PreferencesService.setQuickAddEngineMode(
        QuickAddEngineMode.apiKey,
      );

      await pumpSection(tester);

      expect(find.text(QuickAddEngineMode.apiKey.label), findsOneWidget);
    });
  });
}
