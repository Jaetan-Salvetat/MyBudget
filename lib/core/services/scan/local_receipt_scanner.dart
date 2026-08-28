import 'package:flutter/foundation.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';
import 'package:mybudget/core/services/scan/receipt_image_enhancer.dart';
import 'package:mybudget/core/services/scan/receipt_line_recognizer.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

typedef ReceiptImageEnhancer = Future<Uint8List> Function(Uint8List bytes);

/// Ce que le flow local a lu d'un ticket. [source] dit quelle lecture de
/// l'image a porté la somme prouvée ; elle n'autorise rien, elle informe
/// l'écran d'édition.
class LocalReceiptScan {
  const LocalReceiptScan({
    required this.source,
    required this.store,
    required this.date,
    required this.total,
    required this.items,
    this.trace = const [],
  });

  final ReadSource source;
  final String? store;
  final String? date;
  final double? total;
  final List<ExtractedItem> items;

  /// Ce que chaque lecture tentée a produit. Rien ne s'en sert pour décider :
  /// c'est ce qu'affiche l'inspecteur de scan, et la seule façon de savoir
  /// pourquoi un article n'est pas là sans rejouer la photo à la main.
  final List<ReadTrace> trace;

  bool get verified => verifiedSources.contains(source);
}

/// Le flow local complet sur une photo : le tagger de rôles étiquette toutes
/// les lignes, le décodeur retient l'étiquetage dont la somme retombe au
/// centime. Si rien ne prouve la somme, seulement alors la seconde passe
/// prétraitée — l'étage cher — puis la fusion des deux lectures.
class LocalReceiptScanner {
  final ReceiptLineRecognizer _recognizer;
  final RoleTagger _tagger;
  final LabelLinkModel _link;
  final LabelSpanModel _span;
  final ReceiptImageEnhancer _enhance;

  /// Le répertoire d'enseignes est **optionnel** : sans lui, `storeOf`
  /// retombe sur la ligne que le tagger désigne, recopiée telle quelle —
  /// exactement le comportement d'avant son portage. Le code peut donc
  /// précéder l'asset sans casser l'app.
  final Gazetteer? _gazetteer;

  const LocalReceiptScanner({
    required this._recognizer,
    required this._tagger,
    required this._link,
    required this._span,
    this._gazetteer,
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

    final outcome = await decideLocal(
      pass1,
      _tagger.probabilities,
      secondPass: () => _retryLines(imageBytes),
    );
    step('tagger de rôles + décodeur (${outcome.source.name})');

    if (outcome.items.isEmpty) throw const ScanNoItemsException();

    // Les modèles de libellé travaillent sur les lignes de la lecture
    // retenue — passe 1, retry ou fusion : `ExtractedItem.lineIndex` les
    // indexe, et rattacher un libellé sur les lignes d'une autre lecture
    // désignerait n'importe quoi. Les rôles, eux, sont déjà payés.
    final lines = outcome.lines;
    final roles = outcome.roles;
    final offsets = _link.offsets(lines);
    final spans = _span.probabilities(lines);
    step('lien et spans (${lines.length} lignes)');

    return LocalReceiptScan(
      source: outcome.source,
      store: storeOf(lines, roles, gazetteer: _gazetteer),
      date: dateOf(lines, roles),
      total: outcome.total,
      items: relabel(outcome.items, lines, offsets, spans),
      trace: outcome.trace,
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
