import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/services/scan/local_receipt_scan.dart';
import 'package:mybudget/core/services/scan/receipt_item_name.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/models/scanned_item_model.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

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
      printedTotal: scan.total,
      verified: scan.verified,
      items: [
        for (final (index, item) in scan.items.indexed)
          _itemOf(item, categorized[index]),
      ],
    );
  }

  ScannedItemModel _itemOf(ExtractedItem item, LinePrediction prediction) {
    final category = _resolver.resolve(prediction.slug);
    return ScannedItemModel(
      name: receiptItemDisplayName(item.name),
      amount: item.amount,
      discount: item.discount,
      categorySlug: category?.slug,
      categoryName: category?.label,
      categoryConfidence: category == null ? 0 : prediction.confidence,
    );
  }
}
