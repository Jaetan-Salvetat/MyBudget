import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/ui/dashboard/widgets/category_summary_card.dart';
import 'package:mybudget/ui/dashboard/models/category_expense_summary.dart';

void main() {
  final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

  testWidgets('CategorySummaryCard displays empty state when list is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategorySummaryCard(categories: const [], formatter: formatter),
        ),
      ),
    );

    expect(find.text('Aucune dépense ce mois-ci'), findsOneWidget);
  });

  testWidgets('CategorySummaryCard displays items correctly', (tester) async {
    final categories = [
      CategoryExpenseSummary(
        categoryName: 'Food',
        amount: 100,
        percentage: 0.5,
        color: Colors.red,
        icon: Icons.fastfood,
        categoryId: 1,
      ),
      CategoryExpenseSummary(
        categoryName: 'Transport',
        amount: 50,
        percentage: 0.25,
        color: Colors.blue,
        icon: Icons.directions_car,
        categoryId: 2,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategorySummaryCard(
            categories: categories,
            formatter: formatter,
          ),
        ),
      ),
    );

    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);

    expect(find.textContaining('100,00'), findsOneWidget);
    expect(find.textContaining('50,00'), findsOneWidget);

    expect(find.text('50%'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
  });
}
