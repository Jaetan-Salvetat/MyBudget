import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/services/scan/local_receipt_scan.dart';
import 'package:mybudget/core/services/scan/receipt_item_name.dart';
import 'package:mybudget/core/time/clock.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/models/scanned_item_model.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

class ReceiptScanComposer {
  const ReceiptScanComposer({
    required this._categorizer,
    required this._resolver,
    required this._clock,
  });
  final ReceiptCategorizer _categorizer;
  final CategoryDisplayResolver _resolver;
  final Clock _clock;

  Future<ReceiptScanResultModel> compose(LocalReceiptScan scan) async {
    final categorized = await _categorizer.categorize([
      for (final item in scan.items) item.name,
    ]);

    return ReceiptScanResultModel(
      storeName: scan.store,
      date: _dateOf(scan.date),
      printedTotal: scan.total,
      verified: scan.verified,
      items: [
        for (final (index, item) in scan.items.indexed)
          _itemOf(item, categorized[index]),
      ],
    );
  }

  DateTime _dateOf(String? raw) {
    if (raw == null) return _clock();
    return DateTime.tryParse(raw) ?? _clock();
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
