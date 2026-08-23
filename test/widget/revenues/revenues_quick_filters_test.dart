import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/revenue_group_by.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/revenues/widgets/revenues_quick_filters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CategoryDisplay category(String slug, String label) => CategoryDisplay(
    slug: slug,
    label: label,
    icon: 'paid',
    color: 0xFF4CAF50,
    groupKey: slug,
    groupLabel: label,
    type: TransactionType.income,
  );

  final tapped = <String>[];

  Future<void> pump(
    WidgetTester tester, {
    List<String> selectedGroupKeys = const [],
    List<CategoryDisplay> categories = const [],
  }) {
    tapped.clear();
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: RevenuesQuickFilters(
            axis: RevenueGroupBy.frequency,
            categories: categories,
            selectedGroupKeys: selectedGroupKeys,
            onOpenGroupBy: () => tapped.add('groupBy'),
            onCategoryTap: (key) => tapped.add('category:$key'),
            onClear: () => tapped.add('clear'),
          ),
        ),
      ),
    );
  }

  testWidgets('opens the grouping menu from the axis chip', (tester) async {
    await pump(tester);

    await tester.tap(find.text(RevenueGroupBy.frequency.label));

    expect(tapped, ['groupBy']);
  });

  testWidgets('offers one chip per income category', (tester) async {
    await pump(
      tester,
      categories: [
        category('salaire', 'Salaire'),
        category('transfert', 'Transfert'),
      ],
    );

    expect(find.text('Salaire'), findsOneWidget);

    await tester.tap(find.text('Transfert'));

    expect(tapped, ['category:transfert']);
  });

  testWidgets('clears the selection from the leading chip', (tester) async {
    await pump(
      tester,
      categories: [category('salaire', 'Salaire')],
      selectedGroupKeys: const ['salaire'],
    );

    await tester.tap(find.text('Toutes'));

    expect(tapped, ['clear']);
  });
}
