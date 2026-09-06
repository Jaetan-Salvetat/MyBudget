import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/common/widgets/date_selector.dart';

void main() {
  late BuildContext hostContext;

  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  Future<void> pumpHost(WidgetTester tester) {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
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

  group('DateSelector.showFor', () {
    Future<void> openFor(WidgetTester tester, Frequency frequency) async {
      await pumpHost(tester);
      DateSelector.showFor(
        context: hostContext,
        frequency: frequency,
        initialDate: DateTime(2026, 5, 12),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('un ponctuel ouvre le calendrier complet', (tester) async {
      await openFor(tester, Frequency.oneTime);

      expect(find.byType(FrostedCalendar), findsOneWidget);
    });

    testWidgets('un mensuel ne demande que le jour du mois', (tester) async {
      await openFor(tester, Frequency.monthly);

      expect(find.text('Choisir le jour du mois'), findsOneWidget);
      expect(find.byType(FrostedCalendar), findsNothing);
    });

    testWidgets('un annuel demande le mois et le jour', (tester) async {
      await openFor(tester, Frequency.annual);

      expect(find.text('Choisir la date'), findsOneWidget);
      expect(find.byType(FrostedCalendar), findsNothing);
    });
  });

  group('DateSelector.labelFor', () {
    final date = DateTime(2026, 5, 12);

    test('un ponctuel se lit avec son année', () {
      expect(DateSelector.labelFor(Frequency.oneTime, date), '12 mai 2026');
    });

    test('un mensuel ne retient que le jour du mois', () {
      expect(DateSelector.labelFor(Frequency.monthly, date), 'Le 12 du mois');
    });

    test('un annuel garde le mois, pas l\'année', () {
      expect(DateSelector.labelFor(Frequency.annual, date), '12 mai');
    });
  });
}
