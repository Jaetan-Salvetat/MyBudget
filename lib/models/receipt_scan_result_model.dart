import 'package:mybudget/models/scanned_item_model.dart';

class ReceiptScanResultModel {
  final String? storeName;
  final DateTime? date;
  final List<ScannedItemModel> items;

  const ReceiptScanResultModel({
    this.storeName,
    this.date,
    required this.items,
  });

  ReceiptScanResultModel copyWith({
    String? storeName,
    DateTime? date,
    List<ScannedItemModel>? items,
  }) {
    return ReceiptScanResultModel(
      storeName: storeName ?? this.storeName,
      date: date ?? this.date,
      items: items ?? this.items,
    );
  }
}
