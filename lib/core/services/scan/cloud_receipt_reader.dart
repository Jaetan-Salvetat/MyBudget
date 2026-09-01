import 'package:flutter/foundation.dart';

import 'package:mybudget/core/constants/receipt_schema.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/core/services/scan/cloud_receipt_prompt.dart';
import 'package:mybudget/core/services/scan/local_receipt_scan.dart';
import 'package:mybudget/core/services/scan/receipt_image_enhancer.dart';
import 'package:mybudget/core/services/scan/receipt_read_parser.dart';

typedef ReceiptImagePreparer = Future<Uint8List> Function(Uint8List bytes);

class CloudReceiptReader {
  const CloudReceiptReader({
    required this._client,
    this._prepare = prepareReceiptForUpload,
  });

  final AiChatClient _client;
  final ReceiptImagePreparer _prepare;

  Future<LocalReceiptScan?> read(Uint8List imageBytes) async {
    final Uint8List jpeg;
    try {
      jpeg = await _prepare(imageBytes);
    } on FormatException catch (error) {
      debugPrint('[scan] photo impossible à préparer : $error');
      return null;
    }

    final String raw;
    try {
      raw = await _client.complete(
        prompt: cloudReceiptPrompt,
        schemaName: ReceiptSchema.name,
        schema: cloudReceiptSchema,
        image: AiImageAttachment.jpeg(jpeg),
      );
    } on AiRequestException catch (error) {
      debugPrint('[scan] le modèle distant a renoncé : ${error.failure.name}');
      return null;
    }

    return receiptScanOf(raw);
  }
}
