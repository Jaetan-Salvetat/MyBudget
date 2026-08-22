import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/settings/widgets/sections/about_section.dart';
import 'package:mybudget/ui/settings/widgets/sections/appearance_section.dart';
import 'package:mybudget/ui/settings/widgets/sections/help_and_support_section.dart';
import 'package:mybudget/ui/settings/widgets/sections/input_section.dart';
import 'package:mybudget/ui/settings/update_provider.dart';
import 'package:app_updater/app_updater.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubUpdateNotifier extends UpdateNotifier {
  _StubUpdateNotifier(this._state);

  final UpdateState _state;

  @override
  UpdateState build() => _state;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget section, {
    UpdateState? update,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (update != null)
            updateProvider.overrideWith(() => _StubUpdateNotifier(update)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(body: SingleChildScrollView(child: section)),
        ),
      ),
    );
  }

  FrostedListSection sectionOf(WidgetTester tester) =>
      tester.widget<FrostedListSection>(find.byType(FrostedListSection));

  group('settings sections', () {
    testWidgets('each one is a design-system list section', (
      WidgetTester tester,
    ) async {
      final Map<Widget, String> sections = <Widget, String>{
        const AppearanceSection(): 'Apparence',
        const InputSection(): 'Saisie',
        const HelpAndSupportSection(): 'Aide & Support',
      };

      for (final MapEntry<Widget, String> entry in sections.entries) {
        await pump(tester, entry.key);

        expect(find.byType(FrostedListSection), findsOneWidget);
        expect(sectionOf(tester).label, entry.value);
      }
    });

    testWidgets('tiles carry the design-system avatar, not a custom badge', (
      WidgetTester tester,
    ) async {
      await pump(tester, const InputSection());

      final List<FrostedListTile> tiles = sectionOf(tester).tiles;

      expect(tiles, hasLength(2));
      for (final FrostedListTile tile in tiles) {
        expect(tile.leading, isA<FrostedListAvatar>());
      }
    });

    testWidgets('a navigating tile ends with a chevron', (
      WidgetTester tester,
    ) async {
      await pump(tester, const InputSection());

      expect(
        find.descendant(
          of: find.byType(FrostedListTile).first,
          matching: find.byIcon(Symbols.chevron_right_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('help and support only offers the usage guide', (
      WidgetTester tester,
    ) async {
      await pump(tester, const HelpAndSupportSection());

      final FrostedListTile tile = sectionOf(tester).tiles.single;

      expect(tile.title, 'Guide d\'utilisation');
    });

    testWidgets('the appearance tile reads the current theme mode', (
      WidgetTester tester,
    ) async {
      await pump(tester, const AppearanceSection());

      final FrostedListTile tile = sectionOf(tester).tiles.single;

      expect(tile.title, 'Thème');
      expect(tile.subtitle, 'Automatique');
    });

    testWidgets('the version tile shows no badge without an update', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const AboutSection(),
        update: const UpdateState(currentVersion: '1.2.3'),
      );

      expect(find.text('1.2.3'), findsOneWidget);
      expect(find.byType(FrostedBadgeView), findsNothing);
    });

    testWidgets('the version tile badges an available update', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const AboutSection(),
        update: UpdateState(
          currentVersion: '1.2.3',
          availableUpdate: ReleaseInfo(
            version: '2.0.0',
            tagName: 'v2.0.0',
            title: 'Nouvelle version',
            notes: '',
            publishedAt: DateTime(2026, 8, 22),
            isPrerelease: false,
            assets: const <ReleaseAsset>[],
          ),
        ),
      );

      expect(find.byType(FrostedBadgeView), findsOneWidget);
    });
  });
}
