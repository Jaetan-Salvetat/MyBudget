import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/core/values/category_display.dart';
import 'package:mybudget/data/model/receipt_scan_result_model.dart';
import 'package:mybudget/data/model/scanned_item_model.dart';

const CategoryDisplay boulangerie = CategoryDisplay(
  slug: 'alimentation.boulangerie',
  label: 'Boulangerie',
  icon: 'bakery_dining',
  color: 0xFFF4A261,
  groupKey: 'alimentation',
  groupLabel: 'Alimentation',
  type: TransactionType.expense,
);

const CategoryDisplay entretien = CategoryDisplay(
  slug: 'maison.entretien',
  label: 'Entretien',
  icon: 'cleaning_services',
  color: 0xFF6F8DD8,
  groupKey: 'maison',
  groupLabel: 'Maison',
  type: TransactionType.expense,
);

const List<CategoryDisplay> categories = [boulangerie, entretien];

CategoryDisplay? resolveCategory(String? slug) {
  if (slug == null) return null;
  for (final category in categories) {
    if (category.slug == slug) return category;
  }
  return null;
}

ScannedItemModel scannedItem({
  String name = 'Pain complet',
  double amount = 2.0,
  double discount = 0,
  String? slug = 'alimentation.boulangerie',
  double confidence = 0.9,
  bool confirmed = false,
}) {
  return ScannedItemModel(
    name: name,
    amount: amount,
    discount: discount,
    categorySlug: slug,
    categoryName: resolveCategory(slug)?.label,
    categoryConfidence: confidence,
    confirmedByUser: confirmed,
  );
}

ReceiptScanResultModel scanResult({
  String? storeName = 'Carrefour Market',
  double? printedTotal,
  List<ScannedItemModel>? items,
}) {
  return ReceiptScanResultModel(
    storeName: storeName,
    date: DateTime(2026, 8, 31),
    printedTotal: printedTotal,
    items: items ?? [scannedItem()],
  );
}

Widget scanHarness(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}
