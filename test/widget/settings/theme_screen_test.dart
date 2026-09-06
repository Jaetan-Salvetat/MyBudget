import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/core/theme/theme_mode_display.dart';
import 'package:mybudget/core/theme/theme_provider.dart';
import 'package:mybudget/ui/settings/screens/theme_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.dark(), home: const ThemeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists every theme mode', (tester) async {
    await pumpScreen(tester);

    for (final mode in ThemeMode.values) {
      expect(find.text(mode.label), findsOneWidget);
    }
  });

  testWidgets('tapping a mode selects it', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(ThemeMode.dark.label));
    await tester.pumpAndSettle();

    expect(container.read(themeProvider).themeMode, ThemeMode.dark);
  });

  testWidgets('the selection is persisted', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(ThemeMode.light.label));
    await tester.pumpAndSettle();

    expect(PreferencesService.getThemeMode(), ThemeMode.light);
  });

  testWidgets('stays on the screen after a selection', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(ThemeMode.dark.label));
    await tester.pumpAndSettle();

    expect(find.byType(ThemeScreen), findsOneWidget);
  });
}
