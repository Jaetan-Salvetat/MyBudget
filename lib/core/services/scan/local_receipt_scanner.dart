import 'package:flutter/foundation.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';
import 'package:mybudget/core/services/scan/receipt_image_enhancer.dart';
import 'package:mybudget/core/services/scan/receipt_line_recognizer.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

typedef ReceiptImageEnhancer = Future<Uint8List> Function(Uint8List bytes);

/// Ce que le flow local a lu d'un ticket. [stage] dit par quel étage la somme
/// a été vérifiée ; il n'autorise rien, il informe l'écran d'édition.
class LocalReceiptScan {
  const LocalReceiptScan({
    required this.stage,
    required this.store,
    required this.date,
    required this.total,
    required this.items,
  });

  final FlowStage stage;
  final String? store;
  final String? date;
  final double? total;
  final List<ExtractedItem> items;

  bool get verified => verifiedStages.contains(stage);
}

/// Le flow local complet sur une photo. Passe 1 : règles, puis classifieur
/// (argmax, décodage sous contrainte). Si rien ne vérifie, seulement alors la
/// seconde passe prétraitée — l'étage cher — avec les mêmes étages, puis la
/// fusion des deux passes.
class LocalReceiptScanner {
  final ReceiptLineRecognizer _recognizer;
  final LineClassifier _classifier;
  final RoleTagger _tagger;
  final LabelLinkModel _link;
  final LabelSpanModel _span;
  final ReceiptImageEnhancer _enhance;

  const LocalReceiptScanner({
    required this._recognizer,
    required this._classifier,
    required this._tagger,
    required this._link,
    required this._span,
    this._enhance = enhanceReceiptForRetry,
  });

  Future<LocalReceiptScan> scan(Uint8List imageBytes) async {
    // Le scan tourne sur des photos de 30+ Mpx et sur des téléphones de
    // plusieurs générations : sans mesure par étage, une régression de
    // latence est invisible jusqu'à ce qu'un utilisateur la subisse.
    final watch = Stopwatch()..start();
    var mark = 0;
    void step(String label) {
      debugPrint('[scan] $label : ${watch.elapsedMilliseconds - mark} ms');
      mark = watch.elapsedMilliseconds;
    }

    final pass1 = await _recognizer.recognize(imageBytes);
    step('OCR passe 1 (${pass1.length} lignes)');
    if (pass1.isEmpty) throw const ScanUnreadableException();

    final local = extract(pass1);
    var outcome = decideFirstPass(
      local,
      pass1,
      _classifier,
      FlowPolicy.recommended,
    );
    step('règles + classifieur');

    ExtractedReceipt? retryReceipt;
    if (!outcome.verified) {
      final retry = await _retryLines(imageBytes);
      if (retry != null && retry.isNotEmpty) {
        retryReceipt = extract(retry);
        outcome = decideRetryPass(
          local,
          retryReceipt,
          pass1,
          retry,
          _classifier,
          FlowPolicy.recommended,
        );
        step('retry (2e OCR + étages)');
      }
    }

    if (outcome.items.isEmpty) throw const ScanNoItemsException();

    // Les modèles travaillent sur les lignes dont l'extraction retenue est
    // issue — passe 1, retry ou fusion : `ExtractedItem.lineIndex` les indexe,
    // et rattacher un libellé sur les lignes d'une autre passe désignerait
    // n'importe quoi.
    final lines = outcome.sourceLines.isEmpty ? pass1 : outcome.sourceLines;
    final roles = _tagger.probabilities(lines);
    final offsets = _link.offsets(lines);
    final spans = _span.probabilities(lines);
    step('tagger de rôles, lien et spans (${lines.length} lignes)');

    // Dès qu'on a dû aller en seconde passe, c'est elle qui porte la lecture
    // retenue : son enseigne et sa date priment, la première ne comble que
    // ce qu'elle n'a pas lu.
    final reference = retryReceipt ?? local;
    final fallback = retryReceipt == null ? null : local;
    return LocalReceiptScan(
      stage: outcome.stage,
      store: storeOf(lines, roles) ?? reference.store ?? fallback?.store,
      date: dateOf(lines, roles) ?? reference.date ?? fallback?.date,
      total: outcome.total,
      items: relabel(outcome.items, lines, offsets, spans),
    );
  }

  /// Une seconde passe qui échoue techniquement (image indéchiffrable, moteur
  /// en erreur) ne doit pas faire perdre la première : on continue sans elle.
  Future<List<PhysicalLine>?> _retryLines(Uint8List imageBytes) async {
    try {
      return await _recognizer.recognize(await _enhance(imageBytes));
    } catch (error, stackTrace) {
      debugPrint('Seconde passe OCR impossible : $error\n$stackTrace');
      return null;
    }
  }
}
