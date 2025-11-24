import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/core/theme/theme_viewmodel.dart';
import 'package:mybudget/ui/settings/widgets/sections/appearance_section.dart';
import 'package:provider/provider.dart';

class MockThemeViewModel extends Mock implements ThemeViewModel {}

void main() {
  late MockThemeViewModel mockThemeViewModel;

  setUp(() {
    mockThemeViewModel = MockThemeViewModel();

    when(() => mockThemeViewModel.themeMode).thenReturn(ThemeMode.system);
    when(() => mockThemeViewModel.themeType).thenReturn(AppThemeType.purple);
    when(
      () => mockThemeViewModel.getLightTheme(
        dynamicColorScheme: any(named: 'dynamicColorScheme'),
      ),
    ).thenReturn(ThemeData.light());
    when(
      () => mockThemeViewModel.getDarkTheme(
        dynamicColorScheme: any(named: 'dynamicColorScheme'),
      ),
    ).thenReturn(ThemeData.dark());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<ThemeViewModel>.value(
          value: mockThemeViewModel,
          child: const AppearanceSection(),
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

  testWidgets('Tapping on a color option calls setThemeType', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    final gestureDetectors = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(GestureDetector),
    );

    await tester.tap(gestureDetectors.at(3));
    await tester.pump();

    verify(() => mockThemeViewModel.setThemeType(AppThemeType.blue)).called(1);
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

    verify(
      () => mockThemeViewModel.setThemeType(AppThemeType.dynamicColor),
    ).called(1);
  });
}
