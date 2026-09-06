import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/settings/widgets/sections/debug_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();
  });

  group('DebugSection', () {
    testWidgets('offers only the onboarding reset', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: DebugSection()),
        ),
      );

      final FrostedListTile tile = tester
          .widget<FrostedListSection>(find.byType(FrostedListSection))
          .tiles
          .single;

      expect(tile.title, 'Réinitialiser l\'Onboarding');
    });
  });
}
