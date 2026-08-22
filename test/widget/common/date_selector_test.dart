import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/common/widgets/date_selector.dart';

void main() {
  late BuildContext hostContext;

  Future<void> pumpHost(WidgetTester tester) {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr')],
        home: Builder(
          builder: (BuildContext context) {
            hostContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Future<DateTime?> openFullDatePicker(DateTime initialDate) {
    return DateSelector.showFullDatePicker(
      context: hostContext,
      initialDate: initialDate,
    );
  }

  testWidgets('opens the frosted calendar instead of the Material picker', (
    WidgetTester tester,
  ) async {
    await pumpHost(tester);
    final Future<DateTime?> result = openFullDatePicker(DateTime(2026, 5, 12));
    await tester.pumpAndSettle();

    expect(find.byType(FrostedCalendar), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsNothing);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(await result, isNull);
  });

  testWidgets('returns the day tapped in the calendar', (
    WidgetTester tester,
  ) async {
    await pumpHost(tester);
    final Future<DateTime?> result = openFullDatePicker(DateTime(2026, 5, 12));
    await tester.pumpAndSettle();

    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(await result, DateTime(2026, 5, 20));
  });
}
