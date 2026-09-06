import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/common/widgets/category_tile.dart';

void main() {
  const leaf = CategoryDisplay(
    slug: 'alimentation.supermarche',
    label: 'Supermarché',
    icon: 'shopping_cart',
    color: 0xFF4CAF50,
    groupKey: 'alimentation',
    groupLabel: 'Alimentation',
    type: TransactionType.expense,
  );

  const group = CategoryDisplay(
    slug: 'alimentation',
    label: 'Alimentation',
    icon: 'restaurant',
    color: 0xFF4CAF50,
    groupKey: 'alimentation',
    groupLabel: 'Alimentation',
    type: TransactionType.expense,
  );

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: child),
    ),
  );

  FrostedListTile tileOf(WidgetTester tester) =>
      tester.widget<FrostedListTile>(find.byType(FrostedListTile));

  testWidgets('a leaf row paints no surface of its own', (tester) async {
    await pump(tester, const CategoryTile(category: leaf));

    expect(tileOf(tester).variant, FrostedListTileVariant.plain);
  });

  testWidgets('a group row paints no surface of its own', (tester) async {
    await pump(tester, const CategoryTile(category: group));

    expect(tileOf(tester).variant, FrostedListTileVariant.plain);
  });
}
