import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/feature_stage.dart';
import 'package:mybudget/core/models/feature_flag.dart';
import 'package:mybudget/core/models/flag_blocklist.dart';
import 'package:mybudget/core/providers/feature_flags_provider.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/settings/screens/labs_screen.dart';
import 'package:mybudget/ui/settings/widgets/feature_flag_warning_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int testBuild = 42;
const double scrollStep = 200;

const FeatureFlag enabledFlag = FeatureFlag(
  id: 'ticketScan',
  label: 'Scan de tickets',
  description: 'Remplit une dépense depuis la photo d\'un ticket',
  risk: 'Les montants lus peuvent être faux',
  stage: FeatureStage.beta,
  defaultEnabled: true,
);

const FeatureFlag disabledFlag = FeatureFlag(
  id: 'smartEntry',
  label: 'Saisie intelligente',
  description: 'Devine le montant et la catégorie depuis une phrase',
  risk: 'La catégorie proposée peut être fausse',
  stage: FeatureStage.experimental,
  defaultEnabled: false,
);

const List<FeatureFlag> testFlags = <FeatureFlag>[enabledFlag, disabledFlag];

class _BlockedEverything extends FlagBlocklistNotifier {
  @override
  FlagBlocklist build() {
    return const FlagBlocklist(<String, Set<int>?>{
      'ticketScan': null,
      'smartEntry': null,
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<FeatureFlag> flags = testFlags,
    bool blocked = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appBuildNumberProvider.overrideWithValue('$testBuild'),
          featureFlagRegistryProvider.overrideWithValue(flags),
          if (blocked)
            flagBlocklistProvider.overrideWith(_BlockedEverything.new),
        ],
        child: MaterialApp(
          theme: FrostedTheme.light(seedColor: const Color(0xFF2A55D3)),
          home: const LabsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('LabsScreen', () {
    testWidgets('avertit globalement avant de lister les fonctionnalités', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      final FrostedBanner banner = tester.widget<FrostedBanner>(
        find.byType(FrostedBanner),
      );

      expect(banner.tone, FrostedBannerTone.warning);
      for (final FeatureFlag flag in testFlags) {
        expect(find.text(flag.label), findsOneWidget);
        expect(find.text(flag.risk), findsOneWidget);
      }
    });

    testWidgets('reflète le défaut de chaque fonctionnalité', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      final Iterable<FrostedSwitch> switches = tester.widgetList<FrostedSwitch>(
        find.byType(FrostedSwitch),
      );

      expect(
        switches.map((FrostedSwitch item) => item.value),
        testFlags.map((FeatureFlag flag) => flag.defaultEnabled),
      );
    });

    testWidgets('demande confirmation avant d\'activer', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text(disabledFlag.label));
      await tester.pumpAndSettle();

      expect(find.byType(FeatureFlagWarningDialog), findsOneWidget);
      expect(PreferencesService.getFlagChoice(disabledFlag.id), isNull);
    });

    testWidgets('n\'active rien quand la confirmation est refusée', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text(disabledFlag.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(PreferencesService.getFlagChoice(disabledFlag.id), isNull);
    });

    testWidgets('retient l\'activation une fois confirmée', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text(disabledFlag.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activer'));
      await tester.pumpAndSettle();

      expect(PreferencesService.getFlagChoice(disabledFlag.id), isTrue);
    });

    testWidgets('désactive sans confirmation', (WidgetTester tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text(enabledFlag.label));
      await tester.pumpAndSettle();

      expect(find.byType(FeatureFlagWarningDialog), findsNothing);
      expect(PreferencesService.getFlagChoice(enabledFlag.id), isFalse);
    });

    testWidgets('rend l\'interrupteur inerte quand le blocage est actif', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, blocked: true);

      final Iterable<FrostedSwitch> switches = tester.widgetList<FrostedSwitch>(
        find.byType(FrostedSwitch),
      );

      expect(switches.every((FrostedSwitch item) => !item.value), isTrue);
      expect(
        switches.every((FrostedSwitch item) => item.onChanged == null),
        isTrue,
      );
      expect(
        find.text(LabsScreen.blockedNote),
        findsNWidgets(testFlags.length),
      );
    });

    testWidgets('remet tous les choix au défaut', (WidgetTester tester) async {
      await PreferencesService.setFlagChoice(disabledFlag.id, true);
      await pumpScreen(tester);

      await tester.scrollUntilVisible(
        find.text(LabsScreen.resetLabel),
        scrollStep,
      );
      await tester.ensureVisible(find.text(LabsScreen.resetLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(LabsScreen.resetLabel));
      await tester.pumpAndSettle();

      expect(PreferencesService.getFlagChoice(disabledFlag.id), isNull);
    });

    testWidgets('annonce un registre vide sans proposer de réinitialisation', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, flags: const <FeatureFlag>[]);

      expect(find.text(LabsScreen.emptyNote), findsOneWidget);
      expect(find.byType(FrostedSwitch), findsNothing);
      expect(find.text(LabsScreen.resetLabel), findsNothing);
    });
  });
}
