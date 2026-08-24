/// Sérialisation JSON des extractions, partagée par les bancs de test
/// (harnais on-device, outil de parité) : le format est celui que les
/// scripts Python d'analyse consomment.
library;

import 'structure.dart';

Map<String, Object?> receiptJson(ExtractedReceipt receipt) {
  return {
    'store': receipt.store,
    'date': receipt.date,
    'total': receipt.total,
    'subtotal': receipt.subtotal,
    'payment': receipt.payment,
    'checksum_ok': receipt.checksumOk,
    'items': [
      for (final item in receipt.items)
        {'name': item.name, 'amount': item.amount, 'discount': item.discount},
    ],
  };
}
