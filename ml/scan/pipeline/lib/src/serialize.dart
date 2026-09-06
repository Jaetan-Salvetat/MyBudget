library;

import 'flow.dart';
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

String sourceName(ReadSource source) => switch (source) {
  ReadSource.pass1 => 'passe1',
  ReadSource.retry => 'retry',
  ReadSource.fused => 'fusion',
  ReadSource.confirm => 'confirm',
};
