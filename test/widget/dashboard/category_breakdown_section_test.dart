import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mybudget/ui/dashboard/models/category_expense_summary.dart';
import 'package:mybudget/ui/dashboard/widgets/category_breakdown_section.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('fr_FR');
  });

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders empty state when no categories', (tester) async {
    await tester.pumpWidget(host(const CategoryBreakdownSection(categories: [])));
    expect(find.text('Aucune dépense ce mois-ci'), findsOneWidget);
  });

  testWidgets('renders top categories with name and percent', (tester) async {
    final categories = [
      CategoryExpenseSummary(
        categoryName: 'Logement',
        amount: 720,
        percentage: 0.5,
        color: Colors.blue,
        icon: Icons.home,
        categoryId: 1,
      ),
      CategoryExpenseSummary(
        categoryName: 'Alimentation',
        amount: 280,
        percentage: 0.2,
        color: Colors.orange,
        icon: Icons.restaurant,
        categoryId: 2,
      ),
    ];

    await tester.pumpWidget(
      host(CategoryBreakdownSection(categories: categories)),
    );

    expect(find.text('Logement'), findsOneWidget);
    expect(find.text('Alimentation'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
  });

  testWidgets('invokes onCategoryTap with the right id', (tester) async {
    int? tappedId;
    final categories = [
      CategoryExpenseSummary(
        categoryName: 'Logement',
        amount: 720,
        percentage: 0.5,
        color: Colors.blue,
        icon: Icons.home,
        categoryId: 42,
      ),
    ];

    await tester.pumpWidget(
      host(
        CategoryBreakdownSection(
          categories: categories,
          onCategoryTap: (id) => tappedId = id,
        ),
      ),
    );

    await tester.tap(find.text('Logement'));
    await tester.pump();

    expect(tappedId, 42);
  });
}
