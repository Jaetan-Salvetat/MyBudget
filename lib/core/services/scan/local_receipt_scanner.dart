import 'package:flutter/foundation.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';
import 'package:mybudget/core/services/scan/local_receipt_scan.dart';
import 'package:mybudget/core/services/scan/nano_receipt_reader.dart';
import 'package:mybudget/core/services/scan/receipt_image_enhancer.dart';
import 'package:mybudget/core/services/scan/receipt_line_recognizer.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

typedef ReceiptImageEnhancer = Future<Uint8List> Function(Uint8List bytes);

class LocalReceiptScanner {
  final ReceiptLineRecognizer _recognizer;
  final RoleTagger _tagger;
  final LabelLinkModel _link;
  final LabelSpanModel _span;
  final ReceiptImageEnhancer _enhance;

  final Gazetteer? _gazetteer;

  final bool _localDecoder;

  const LocalReceiptScanner({
    required this._recognizer,
    required this._tagger,
    required this._link,
    required this._span,
    this._gazetteer,
    this._enhance = enhanceReceiptForRetry,
    this._localDecoder = false,
  });

  Future<LocalReceiptScan> scan(
    Uint8List imageBytes, {
    NanoReceiptReader? nano,
  }) async {
    final watch = Stopwatch()..start();
    var mark = 0;
    void step(String label) {
      debugPrint('[scan] $label : ${watch.elapsedMilliseconds - mark} ms');
      mark = watch.elapsedMilliseconds;
    }

    final Future<void>? warmingUp = nano?.warmUp();

    final pass1 = await _recognizer.recognize(imageBytes);
    step('OCR passe 1 (${pass1.length} lignes)');
    if (pass1.isEmpty) throw const ScanUnreadableException();

    if (nano != null) {
      await warmingUp;
      step('préchauffage Gemini Nano');
      final read = await nano.read(imageBytes, pass1);
      step('lecture Gemini Nano (${read?.items.length ?? 0} articles)');
      if (read != null) return read;
    }

    if (!_localDecoder) throw const ScanUnavailableException();

    final outcome = await decideLocal(
      pass1,
      _tagger.probabilities,
      secondPass: () => _retryLines(imageBytes),
    );
    step('tagger de rôles + décodeur (${outcome.source.name})');

    if (outcome.items.isEmpty) throw const ScanNoItemsException();

    final lines = outcome.lines;
    final roles = outcome.roles;
    final offsets = _link.offsets(lines);
    final spans = _span.probabilities(lines);
    step('lien et spans (${lines.length} lignes)');

    return LocalReceiptScan.fromOutcome(
      outcome,
      store: storeOf(lines, roles, gazetteer: _gazetteer),
      date: dateOf(lines, roles),
      items: relabel(outcome.items, lines, offsets, spans),
    );
  }

  Future<List<PhysicalLine>?> _retryLines(Uint8List imageBytes) async {
    try {
      return await _recognizer.recognize(await _enhance(imageBytes));
    } catch (error, stackTrace) {
      debugPrint('Seconde passe OCR impossible : $error\n$stackTrace');
      return null;
    }
  }
}
