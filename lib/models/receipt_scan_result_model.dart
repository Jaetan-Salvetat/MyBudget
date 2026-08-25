import 'package:mybudget/models/scanned_item_model.dart';

class ReceiptScanResultModel {
  final String? storeName;
  final DateTime? date;
  final List<ScannedItemModel> items;

  /// La somme des articles est retombée sur un montant imprimé du ticket.
  /// Sinon la lecture est partielle : l'écran d'édition le dit au lieu
  /// d'afficher un badge de confiance.
  final bool verified;

  const ReceiptScanResultModel({
    this.storeName,
    this.date,
    this.verified = false,
    required this.items,
  });

  ReceiptScanResultModel copyWith({
    String? storeName,
    DateTime? date,
    bool? verified,
    List<ScannedItemModel>? items,
  }) {
    return ReceiptScanResultModel(
      storeName: storeName ?? this.storeName,
      date: date ?? this.date,
      verified: verified ?? this.verified,
      items: items ?? this.items,
    );
  }
}
