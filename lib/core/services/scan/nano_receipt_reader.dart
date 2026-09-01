import 'package:flutter/foundation.dart';

import 'package:mybudget/core/constants/receipt_schema.dart';
import 'package:mybudget/core/enums/gemini_nano_channel.dart';
import 'package:mybudget/core/enums/gemini_nano_failure.dart';
import 'package:mybudget/core/enums/gemini_nano_preference.dart';
import 'package:mybudget/core/services/ai/gemini_nano_service.dart';
import 'package:mybudget/core/services/scan/local_receipt_scan.dart';
import 'package:mybudget/core/services/scan/nano_receipt_prompt.dart';
import 'package:mybudget/core/services/scan/receipt_read_parser.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

class NanoReceiptReader {
  const NanoReceiptReader({
    this._service = const GeminiNanoService(),
    this._channel = GeminiNanoChannel.fallback,
  });

  final GeminiNanoService _service;
  final GeminiNanoChannel _channel;

  Future<void> warmUp() =>
      _service.warmUp(_channel, GeminiNanoPreference.scan);

  Future<LocalReceiptScan?> read(List<PhysicalLine> lines) async {
    final prompt = nanoReceiptPrompt(lines);
    if (prompt == null) return null;

    final String raw;
    try {
      raw = await _service.generate(
        prompt: prompt,
        schema: ReceiptSchema.name,
        channel: _channel,
        preference: GeminiNanoPreference.scan,
      );
    } on GeminiNanoException catch (error) {
      debugPrint('[scan] Gemini Nano a renoncé : ${error.message}');
      return null;
    }

    return receiptScanOf(raw);
  }
}
