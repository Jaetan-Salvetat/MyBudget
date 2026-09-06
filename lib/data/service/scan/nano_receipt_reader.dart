import 'package:flutter/foundation.dart';

import 'package:mybudget/core/constants/receipt_schema.dart';
import 'package:mybudget/core/enums/gemini_nano_channel.dart';
import 'package:mybudget/core/enums/gemini_nano_failure.dart';
import 'package:mybudget/core/enums/gemini_nano_preference.dart';
import 'package:mybudget/data/service/ai/gemini_nano_service.dart';
import 'package:mybudget/data/service/scan/local_receipt_scan.dart';
import 'package:mybudget/data/service/scan/nano_receipt_prompt.dart';
import 'package:mybudget/data/service/scan/receipt_read_parser.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

/// Réglages mesurés au banc du 2026-09-02, 96 tickets FindIt annotés.
/// Chaque section reçoit la photo *et* la transcription OCR : c'est la seule
/// modalité où le thinking apporte quelque chose (+29 −7 sur 36 bascules).
const double _extractionHeat = 0.2;
const int _seed = 42;

/// Les tirages successifs des articles, dans l'ordre mesuré au banc : le
/// premier dont la somme tombe sur le total dédié est gardé. Rejouer et laisser
/// l'arithmétique trancher vaut mieux que le vote majoritaire, qui fait moins
/// bien que le meilleur tirage seul.
const List<({bool transcript, bool thinking})> _itemAttempts = [
  (transcript: true, thinking: true),
  (transcript: true, thinking: false),
  (transcript: false, thinking: false),
  (transcript: false, thinking: true),
];

class NanoReceiptReader {
  const NanoReceiptReader({
    this._service = const GeminiNanoService(),
    this._channel = GeminiNanoChannel.fallback,
  });

  final GeminiNanoService _service;
  final GeminiNanoChannel _channel;

  Future<void> warmUp() => _service.warmUp(_channel, GeminiNanoPreference.scan);

  Future<LocalReceiptScan?> read(
    Uint8List imageBytes,
    List<PhysicalLine> lines, {
    ReceiptReadListener? onPart,
  }) async {
    final transcript = receiptTranscript(lines);
    if (transcript == null) return null;

    final total = await _section(
      totalSectionPrompt,
      ReceiptSchema.totalName,
      transcript,
      imageBytes,
      thinking: false,
    );
    final printed = total == null ? null : sectionTotalOf(total);
    if (printed != null) onPart?.call(ReceiptReadPart(total: printed));

    final store = await _section(
      storeSectionPrompt,
      ReceiptSchema.storeName,
      transcript,
      imageBytes,
      thinking: true,
    );
    final storeName = store == null ? null : sectionStoreOf(store);
    if (storeName != null) onPart?.call(ReceiptReadPart(store: storeName));

    final date = await _section(
      dateSectionPrompt,
      ReceiptSchema.dateName,
      transcript,
      imageBytes,
      thinking: true,
    );
    final readDate = date == null ? null : sectionDateOf(date);
    if (readDate != null) onPart?.call(ReceiptReadPart(date: readDate));

    final articles = await _articles(transcript, imageBytes, printed);
    if (articles == null) return null;

    return LocalReceiptScan(
      store: storeName,
      date: readDate,
      total: articles.total ?? printed,
      items: articles.items,
      verified: articles.proven,
    );
  }

  /// Rejoue la lecture des articles jusqu'à ce qu'une somme tombe sur le total
  /// imprimé. Le vote majoritaire fait moins bien : c'est l'arithmétique qui
  /// tranche, pas la popularité.
  Future<({double? total, List<ExtractedItem> items, bool proven})?> _articles(
    String transcript,
    Uint8List imageBytes,
    double? printed,
  ) async {
    ({double? total, List<ExtractedItem> items})? fallback;

    for (final attempt in _itemAttempts) {
      final raw = await _section(
        itemsSectionPrompt,
        ReceiptSchema.itemsName,
        transcript,
        imageBytes,
        thinking: attempt.thinking,
        withTranscript: attempt.transcript,
      );
      if (raw == null) continue;

      final read = sectionArticlesOf(raw);
      if (read == null) continue;

      if (proves(read.items, printed)) {
        return (total: printed, items: read.items, proven: true);
      }
      fallback ??= read;
    }

    if (fallback == null) return null;
    return (total: fallback.total, items: fallback.items, proven: false);
  }

  Future<String?> _section(
    String task,
    String schema,
    String transcript,
    Uint8List imageBytes, {
    required bool thinking,
    bool withTranscript = true,
  }) async {
    try {
      return await _service.generate(
        prompt: withTranscript ? sectionPrompt(task, transcript) : task,
        schema: schema,
        channel: _channel,
        preference: GeminiNanoPreference.scan,
        image: imageBytes,
        temperature: _extractionHeat,
        seed: _seed,
        schemaInPrompt: true,
        thinking: thinking,
      );
    } on GeminiNanoException catch (error) {
      debugPrint('[scan] section $schema abandonnée : ${error.message}');
      return null;
    }
  }
}
