import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/services/scan/local_receipt_scanner.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/models/scanned_item_model.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

/// Habille ce que le flow local a lu : la catégorie de chaque article, libellés
/// résolus dans la taxonomie de l'utilisateur. Un article se classe sur son
/// seul libellé — l'enseigne du ticket n'entre pas dans la décision. Une
/// catégorie que la taxonomie ne connaît pas n'est pas inventée : l'article
/// part sans catégorie et l'écran d'édition la demande.
class ReceiptScanComposer {
  final ReceiptCategorizer _categorizer;
  final CategoryDisplayResolver _resolver;

  const ReceiptScanComposer({
    required this._categorizer,
    required this._resolver,
  });

  Future<ReceiptScanResultModel> compose(LocalReceiptScan scan) async {
    final categorized = await _categorizer.categorize([
      for (final item in scan.items) item.name,
    ]);

    return ReceiptScanResultModel(
      storeName: scan.store,
      date: scan.date == null ? null : DateTime.tryParse(scan.date!),
      verified: scan.verified,
      items: [
        for (final (index, item) in scan.items.indexed)
          _itemOf(item, categorized[index].slug),
      ],
    );
  }

  ScannedItemModel _itemOf(ExtractedItem item, String slug) {
    final category = _resolver.resolve(slug);
    return ScannedItemModel(
      name: item.name,
      amount: item.amount,
      discount: item.discount,
      categorySlug: category?.slug,
      categoryName: category?.label,
    );
  }
}
