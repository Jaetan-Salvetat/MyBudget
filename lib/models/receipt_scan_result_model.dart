import 'package:mybudget/models/scanned_item_model.dart';

class ReceiptScanResultModel {
  final String? storeName;
  DateTime? date;
  final List<ScannedItemModel> items;

  ReceiptScanResultModel({
    this.storeName,
    this.date,
    required this.items,
  });
}
