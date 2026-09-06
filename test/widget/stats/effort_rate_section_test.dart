import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/percent_formatter.dart';
import 'package:mybudget/ui/stats/widgets/effort_rate_section.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('fr_FR');
  });

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  Widget section({
    double? rate = 0.31,
    double? annualRate = 0.42,
    double recurringExpenses = 620,
    double leftover = 1380,
  }) => host(
    EffortRateSection(
      rate: rate,
      annualRate: annualRate,
      recurringExpenses: recurringExpenses,
      leftover: leftover,
    ),
  );

  testWidgets('states the rate and both amounts', (tester) async {
    await tester.pumpWidget(section());

    expect(find.text(PercentFormatter.formatWhole(31)), findsOneWidget);
    expect(find.textContaining('Fixe'), findsOneWidget);
    expect(find.textContaining('Reste à vivre'), findsOneWidget);
  });

  testWidgets('recalls the twelve month rate', (tester) async {
    await tester.pumpWidget(section());

    expect(find.textContaining('${PercentFormatter.formatWhole(42)} sur 12 mois'), findsOneWidget);
  });

  testWidgets('drops the twelve month rate when it reads the same', (
    tester,
  ) async {
    await tester.pumpWidget(section(rate: 0.31, annualRate: 0.312));

    expect(find.textContaining('sur 12 mois'), findsNothing);
  });

  testWidgets('drops the twelve month rate when there is none', (tester) async {
    await tester.pumpWidget(section(annualRate: null));

    expect(find.textContaining('sur 12 mois'), findsNothing);
  });

  testWidgets('paints both split segments', (tester) async {
    await tester.pumpWidget(section());

    final segments = find.descendant(
      of: find.byType(FrostedStackedBar),
      matching: find.byType(DecoratedBox),
    );

    expect(segments, findsNWidgets(2));
    for (var index = 0; index < 2; index++) {
      final size = tester.getSize(segments.at(index));
      expect(size.height, greaterThan(0));
      expect(size.width, greaterThan(0));
    }
  });

  testWidgets('fills the bar when the charges eat the income', (tester) async {
    await tester.pumpWidget(
      section(rate: 1.1, recurringExpenses: 2200, leftover: -200),
    );

    final segments = find.descendant(
      of: find.byType(FrostedStackedBar),
      matching: find.byType(DecoratedBox),
    );

    expect(find.text(PercentFormatter.formatWhole(110)), findsOneWidget);
    expect(segments, findsOneWidget);
    expect(find.textContaining('-200'), findsOneWidget);
  });

  testWidgets('asks for income when there is no rate to show', (tester) async {
    await tester.pumpWidget(section(rate: null, annualRate: null));

    expect(find.textContaining('%'), findsNothing);
    expect(find.byType(FrostedStackedBar), findsNothing);
    expect(find.textContaining('revenus récurrents'), findsOneWidget);
  });
}
