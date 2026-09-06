import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/models/category_override_model.dart';
import 'package:mybudget/ui/capture/models/journal_entry.dart';
import 'package:mybudget/ui/capture/widgets/day_gauge.dart';

const Color fallback = Color(0xFF2A55D3);

JournalEntry entryOf({
  required int id,
  required double amount,
  String? categorySlug,
  TransactionType type = TransactionType.expense,
}) {
  return JournalEntry(
    id: id,
    source: type == TransactionType.income
        ? JournalEntrySource.revenue
        : JournalEntrySource.expense,
    type: type,
    name: 'Ligne $id',
    amount: amount,
    at: DateTime(2026, 8, 29, 12),
    categorySlug: categorySlug,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CategoryDisplayResolver resolver;

  setUpAll(() async {
    final taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
    resolver = CategoryDisplayResolver(
      taxonomy: taxonomy,
      overrides: const <String, CategoryOverrideModel>{},
    );
  });

  const double gaugeWidth = 400;

  List<FrostedBarSegment> segmentsOf(List<double> weights) => [
    for (final weight in weights)
      FrostedBarSegment(color: fallback, value: weight),
  ];

  Future<void> pumpGauge(
    WidgetTester tester,
    List<FrostedBarSegment> segments,
  ) {
    return tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.light(seedColor: fallback),
        home: Center(
          child: SizedBox(
            width: gaugeWidth,
            child: DayGauge(segments: segments),
          ),
        ),
      ),
    );
  }

  double drawnWidth(WidgetTester tester) {
    final bars = find.descendant(
      of: find.byType(DayGauge),
      matching: find.byType(Container),
    );

    return tester
        .widgetList<Container>(bars)
        .indexed
        .fold(0.0, (sum, bar) => sum + tester.getSize(bars.at(bar.$1)).width);
  }

  testWidgets('the bars fill the width they are given, no more', (
    WidgetTester tester,
  ) async {
    await pumpGauge(tester, segmentsOf([60, 40]));
    await tester.pumpAndSettle();

    expect(drawnWidth(tester), lessThanOrEqualTo(gaugeWidth));
    expect(
      drawnWidth(tester),
      moreOrLessEquals(gaugeWidth - DayGauge.gap, epsilon: 0.01),
    );
  });

  testWidgets('a day changing shape never overflows mid-animation', (
    WidgetTester tester,
  ) async {
    await pumpGauge(tester, segmentsOf([60, 40]));
    await tester.pumpAndSettle();

    await pumpGauge(tester, segmentsOf([20, 20, 20, 20, 20]));

    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
      expect(drawnWidth(tester), lessThanOrEqualTo(gaugeWidth));
    }

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('one segment per category, heaviest first', () {
    final segments = DayGauge.segmentsForDay(
      [
        entryOf(id: 1, amount: 4, categorySlug: 'alimentation.supermarche'),
        entryOf(id: 2, amount: 68, categorySlug: 'transport.essence'),
        entryOf(id: 3, amount: 42, categorySlug: 'alimentation.supermarche'),
      ],
      resolver,
      fallback,
    );

    expect(segments.length, 2);
    expect(segments.first.value, 68);
    expect(segments.last.value, 46);
  });

  test('leaves revenues out : the gauge reads what the day cost', () {
    final segments = DayGauge.segmentsForDay(
      [
        entryOf(id: 1, amount: 42, categorySlug: 'alimentation.supermarche'),
        entryOf(
          id: 2,
          amount: 2000,
          categorySlug: 'revenus.salaire',
          type: TransactionType.income,
        ),
      ],
      resolver,
      fallback,
    );

    expect(segments.single.value, 42);
  });

  test('an uncategorised line still weighs on the day', () {
    final segments = DayGauge.segmentsForDay(
      [entryOf(id: 1, amount: 12)],
      resolver,
      fallback,
    );

    expect(segments.single.color, fallback);
  });

  test('never draws more segments than it can show', () {
    final segments = DayGauge.segmentsForDay(
      [
        entryOf(id: 1, amount: 10, categorySlug: 'alimentation.supermarche'),
        entryOf(id: 2, amount: 20, categorySlug: 'transport.essence'),
        entryOf(id: 3, amount: 30, categorySlug: 'logement.loyer'),
        entryOf(id: 4, amount: 40, categorySlug: 'sante.pharmacie'),
        entryOf(id: 5, amount: 50, categorySlug: 'loisirs.sport'),
        entryOf(id: 6, amount: 60, categorySlug: 'restauration.cafe'),
      ],
      resolver,
      fallback,
    );

    expect(segments.length, lessThanOrEqualTo(DayGauge.maxSegments));
  });
}
