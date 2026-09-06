import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/build_flavor.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/settings/widgets/sections/debug_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();
  });

  Future<void> pump(WidgetTester tester, BuildFlavor flavor) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [buildFlavorProvider.overrideWithValue(flavor)],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: DebugSection()),
        ),
      ),
    );
  }

  List<FrostedListTile> tilesOf(WidgetTester tester) =>
      tester.widget<FrostedListSection>(find.byType(FrostedListSection)).tiles;

  group('DebugSection', () {
    testWidgets('offers the update preview on a sideloaded build', (
      WidgetTester tester,
    ) async {
      await pump(tester, BuildFlavor.beta);

      expect(
        tilesOf(tester).map((FrostedListTile tile) => tile.title),
        contains('Tester la page Update'),
      );
    });

    testWidgets('drops the update preview on the store build', (
      WidgetTester tester,
    ) async {
      await pump(tester, BuildFlavor.store);

      final FrostedListTile tile = tilesOf(tester).single;

      expect(tile.title, 'Réinitialiser l\'Onboarding');
    });
  });
}
