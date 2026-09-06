import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/entities/monthly_flow.dart';
import 'package:mybudget/ui/stats/widgets/monthly_flow_section.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('fr_FR');
  });

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  List<MonthlyFlow> flowsOf(List<List<double>> pairs) => [
    for (var index = 0; index < pairs.length; index++)
      MonthlyFlow(
        month: DateTime(2026, index + 1),
        incomes: pairs[index][0],
        expenses: pairs[index][1],
      ),
  ];

  Widget section(
    List<MonthlyFlow> flows, {
    double averageNet = 300,
    double netDelta = -100,
    bool hasComparison = true,
    ValueChanged<DateTime>? onMonthTap,
  }) => host(
    MonthlyFlowSection(
      flows: flows,
      averageNet: averageNet,
      netDelta: netDelta,
      hasComparison: hasComparison,
      onMonthTap: onMonthTap ?? (_) {},
    ),
  );

  testWidgets('announces the average net flow', (tester) async {
    await tester.pumpWidget(
      section(
        flowsOf([
          [1000, 700],
          [1000, 700],
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('+300', findRichText: true), findsOneWidget);
    expect(find.text('mis de côté en moyenne'), findsOneWidget);
  });

  testWidgets('says overdrawn when the average net is negative', (
    tester,
  ) async {
    await tester.pumpWidget(
      section(
        flowsOf([
          [500, 900],
        ]),
        averageNet: -400,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('de découvert en moyenne'), findsOneWidget);
  });

  testWidgets('hides the delta pill without a comparison', (tester) async {
    await tester.pumpWidget(
      section(
        flowsOf([
          [1000, 700],
        ]),
        hasComparison: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('/mois', skipOffstage: false), findsNothing);
  });

  testWidgets('draws one column per month', (tester) async {
    await tester.pumpWidget(
      section(
        flowsOf([
          [1000, 700],
          [1000, 800],
          [1000, 600],
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FractionallySizedBox), findsNWidgets(6));
  });

  testWidgets('draws the expense bar above the income bar in a deficit', (
    tester,
  ) async {
    await tester.pumpWidget(
      section(
        flowsOf([
          [500, 900],
        ]),
      ),
    );
    await tester.pumpAndSettle();

    final factors = tester
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .map((box) => box.heightFactor ?? 0)
        .toList();

    expect(factors, [500 / 900, 1]);
  });

  testWidgets('scales every month against the same peak', (tester) async {
    await tester.pumpWidget(
      section(
        flowsOf([
          [2000, 1000],
          [1000, 500],
        ]),
      ),
    );
    await tester.pumpAndSettle();

    final factors = tester
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .map((box) => box.heightFactor ?? 0)
        .toList();

    expect(factors, [1, 0.5, 0.5, 0.25]);
  });

  testWidgets('reports the tapped month', (tester) async {
    DateTime? tapped;

    await tester.pumpWidget(
      section(
        flowsOf([
          [1000, 700],
        ]),
        onMonthTap: (month) => tapped = month,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(GestureDetector).first);

    expect(tapped, DateTime(2026));
  });

  testWidgets('labels every month of a twelve month window', (tester) async {
    await tester.pumpWidget(
      section(flowsOf(List.generate(12, (_) => [1000.0, 700.0]))),
    );
    await tester.pumpAndSettle();

    for (final label in const [
      'JANV',
      'FÉVR',
      'MARS',
      'AVR',
      'MAI',
      'JUIN',
      'JUIL',
      'AOÛT',
      'SEPT',
      'OCT',
      'NOV',
      'DÉC',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });
}
