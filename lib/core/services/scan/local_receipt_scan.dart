import 'package:receipt_pipeline/receipt_pipeline.dart';

class LocalReceiptScan {
  const LocalReceiptScan({
    required this.store,
    required this.date,
    required this.total,
    required this.items,
    required this.verified,
    this.trace = const [],
  });

  LocalReceiptScan.fromOutcome(
    LocalOutcome outcome, {
    required this.store,
    required this.date,
    required this.items,
  }) : total = outcome.total,
       verified = outcome.verified,
       trace = outcome.trace;

  final String? store;
  final String? date;
  final double? total;
  final List<ExtractedItem> items;

  final bool verified;

  final List<ReadTrace> trace;
}
