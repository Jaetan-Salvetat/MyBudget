import 'dart:typed_data';

import 'package:mybudget/core/services/scan/local_receipt_scan.dart';
import 'package:mybudget/core/services/scan/local_receipt_scanner.dart';
import 'package:mybudget/core/services/scan/nano_receipt_reader.dart';
import 'package:mybudget/core/services/scan/receipt_scan_composer.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

class FakeReceiptScanner implements LocalReceiptScanner {
  Object? _failure;

  void failWith(Object error) => _failure = error;

  @override
  Future<LocalReceiptScan> scan(
    Uint8List imageBytes, {
    NanoReceiptReader? nano,
    ReceiptReadListener? onPart,
  }) async {
    final Object? error = _failure;
    if (error != null) throw error;
    return const LocalReceiptScan(
      store: null,
      date: null,
      total: null,
      items: <ExtractedItem>[],
      verified: false,
      trace: <ReadTrace>[],
    );
  }
}

class FakeReceiptScanComposer implements ReceiptScanComposer {
  FakeReceiptScanComposer(this.result);

  final ReceiptScanResultModel result;

  @override
  Future<ReceiptScanResultModel> compose(LocalReceiptScan scan) async => result;
}
