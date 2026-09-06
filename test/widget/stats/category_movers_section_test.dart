import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/ui/stats/models/category_trend.dart';
import 'package:mybudget/ui/stats/widgets/category_movers_section.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('fr_FR');
  });

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  CategoryTrend trend({
    required String label,
    required double amount,
    required double previousAmount,
  }) => CategoryTrend(
    groupKey: label.toLowerCase(),
    label: label,
    color: Colors.blue,
    amount: amount,
    previousAmount: previousAmount,
  );

  testWidgets('says nothing moved when the comparison is quiet', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        CategoryMoversSection(
          movers: const [],
          comparedMonths: 6,
          hasComparison: true,
          onCategoryTap: (_) {},
        ),
      ),
    );

    expect(find.text('CE QUI A BOUGÉ'), findsOneWidget);
    expect(
      find.text('Aucun poste n\u2019a bougé sur la période'),
      findsOneWidget,
    );
    expect(find.text('vs 6 mois précédents'), findsOneWidget);
  });

  testWidgets('says why it cannot compare without an earlier window', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        CategoryMoversSection(
          movers: const [],
          comparedMonths: 6,
          hasComparison: false,
          onCategoryTap: (_) {},
        ),
      ),
    );

    expect(find.text('CE QUI A BOUGÉ'), findsOneWidget);
    expect(
      find.text(
        'Pas encore assez d\u2019historique pour comparer les 6 mois précédents',
      ),
      findsOneWidget,
    );
    expect(find.text('vs 6 mois précédents'), findsNothing);
  });

  testWidgets('signs a rise and a drop', (tester) async {
    await tester.pumpWidget(
      host(
        CategoryMoversSection(
          movers: [
            trend(label: 'Numérique', amount: 1233, previousAmount: 962),
            trend(label: 'Shopping', amount: 840, previousAmount: 1106),
          ],
          comparedMonths: 6,
          hasComparison: true,
          onCategoryTap: (_) {},
        ),
      ),
    );

    expect(find.text('${MoneyFormatter.plusSign}${MoneyFormatter.formatRounded(271)}'), findsOneWidget);
    expect(find.text('${MoneyFormatter.minusSign}${MoneyFormatter.formatRounded(266)}'), findsOneWidget);
    expect(find.text('vs 6 mois précédents'), findsOneWidget);
  });

  testWidgets('caps the list at five movers', (tester) async {
    await tester.pumpWidget(
      host(
        CategoryMoversSection(
          movers: [
            for (var index = 0; index < 7; index++)
              trend(
                label: 'Poste $index',
                amount: 100.0 * index,
                previousAmount: 0,
              ),
          ],
          comparedMonths: 12,
          hasComparison: true,
          onCategoryTap: (_) {},
        ),
      ),
    );

    expect(find.text('Poste 0'), findsOneWidget);
    expect(find.text('Poste 4'), findsOneWidget);
    expect(find.text('Poste 5'), findsNothing);
  });

  testWidgets('reports the tapped group', (tester) async {
    String? tapped;

    await tester.pumpWidget(
      host(
        CategoryMoversSection(
          movers: [trend(label: 'Loisirs', amount: 300, previousAmount: 100)],
          comparedMonths: 6,
          hasComparison: true,
          onCategoryTap: (groupKey) => tapped = groupKey,
        ),
      ),
    );

    await tester.tap(find.text('Loisirs'));

    expect(tapped, 'loisirs');
  });
}
