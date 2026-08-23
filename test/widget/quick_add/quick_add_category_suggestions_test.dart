import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_category_suggestions.dart';

CategoryDisplay displayOf(String slug, String label) => CategoryDisplay(
  slug: slug,
  label: label,
  icon: 'restaurant',
  color: 0xFFF44336,
  groupKey: slug.split('.').first,
  groupLabel: 'Restauration',
  type: TransactionType.expense,
);

void main() {
  final fastFood = displayOf('restauration.fast_food', 'Fast-food');
  final restaurant = displayOf('restauration.restaurant', 'Restaurant');
  final bar = displayOf('restauration.bar', 'Bar & apéro');

  Future<void> pumpSuggestions(
    WidgetTester tester, {
    required List<CategoryDisplay> suggestions,
    required String selectedSlug,
    ValueChanged<String>? onSelected,
    VoidCallback? onBrowseAll,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: QuickAddCategorySuggestions(
            suggestions: suggestions,
            selectedSlug: selectedSlug,
            onSelected: onSelected ?? (_) {},
            onBrowseAll: onBrowseAll ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('lists every candidate the model returned', (tester) async {
    await pumpSuggestions(
      tester,
      suggestions: [fastFood, restaurant, bar],
      selectedSlug: fastFood.slug,
    );

    expect(find.text('Fast-food'), findsOneWidget);
    expect(find.text('Restaurant'), findsOneWidget);
    expect(find.text('Bar & apéro'), findsOneWidget);
  });

  testWidgets('marks the one currently held by the draft', (tester) async {
    await pumpSuggestions(
      tester,
      suggestions: [fastFood, restaurant, bar],
      selectedSlug: restaurant.slug,
    );

    expect(find.byIcon(Symbols.check_rounded), findsOneWidget);
  });

  testWidgets('keeps a category the model did not suggest in the list', (
    tester,
  ) async {
    await pumpSuggestions(
      tester,
      suggestions: [fastFood, restaurant],
      selectedSlug: bar.slug,
    );

    expect(find.text('Fast-food'), findsOneWidget);
    expect(find.text('Restaurant'), findsOneWidget);
  });

  testWidgets('reports the candidate that was tapped', (tester) async {
    final picked = <String>[];
    await pumpSuggestions(
      tester,
      suggestions: [fastFood, restaurant, bar],
      selectedSlug: fastFood.slug,
      onSelected: picked.add,
    );

    await tester.tap(find.text('Bar & apéro'));
    await tester.pumpAndSettle();

    expect(picked, [bar.slug]);
  });

  testWidgets('offers a way out to the full taxonomy', (tester) async {
    var browsed = 0;
    await pumpSuggestions(
      tester,
      suggestions: [fastFood, restaurant, bar],
      selectedSlug: fastFood.slug,
      onBrowseAll: () => browsed++,
    );

    await tester.tap(find.text('Toutes les catégories'));
    await tester.pumpAndSettle();

    expect(browsed, 1);
  });
}
