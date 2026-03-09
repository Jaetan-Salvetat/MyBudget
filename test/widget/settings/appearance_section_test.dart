import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/core/theme/theme_provider.dart';
import 'package:mybudget/ui/settings/widgets/sections/appearance_section.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mybudget/core/services/preferences_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();
  });

  Widget createWidgetUnderTest() {
    return const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: AppearanceSection(),
        ),
      ),
    );
  }

  testWidgets('AppearanceSection renders correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Apparence'), findsOneWidget);
    expect(find.text('Thème'), findsOneWidget);
    expect(find.text('Couleur principale'), findsOneWidget);
    expect(find.text('Automatique'), findsOneWidget);
  });

  testWidgets('Tapping on a color option updates themeType', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    final gestureDetectors = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(GestureDetector),
    );

    await tester.tap(gestureDetectors.at(3));
    await tester.pump();

    final element = tester.element(find.byType(AppearanceSection));
    final container = ProviderScope.containerOf(element);
    expect(container.read(themeProvider).themeType, AppThemeType.blue);
  });

  testWidgets('Dynamic color option is present and interactable', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    final gestureDetectors = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(GestureDetector),
    );

    await tester.tap(gestureDetectors.at(0));
    await tester.pump();

    final element = tester.element(find.byType(AppearanceSection));
    final container = ProviderScope.containerOf(element);
    expect(container.read(themeProvider).themeType, AppThemeType.dynamicColor);
  });
}
