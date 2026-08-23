import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/core/theme/theme_provider.dart';
import 'package:mybudget/ui/settings/screens/theme_screen.dart';
import 'package:mybudget/ui/settings/widgets/sections/appearance_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: AppearanceSection()),
      ),
    );
  }

  testWidgets('renders title, theme tile and default mode label', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Apparence'), findsOneWidget);
    expect(find.text('Thème'), findsOneWidget);
    expect(find.text('Automatique'), findsOneWidget);
  });

  testWidgets('reflects updated theme mode in subtitle', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    final element = tester.element(find.byType(AppearanceSection));
    final container = ProviderScope.containerOf(element);
    container.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
    await tester.pump();

    expect(find.text('Sombre'), findsOneWidget);
  });

  testWidgets('opens the theme screen', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('Thème'));
    await tester.pumpAndSettle();

    expect(find.byType(ThemeScreen), findsOneWidget);
  });
}
