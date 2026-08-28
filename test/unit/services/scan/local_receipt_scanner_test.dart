import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';
import 'package:mybudget/core/services/scan/local_receipt_scanner.dart';
import 'package:mybudget/core/services/scan/receipt_line_recognizer.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

import '../../../helpers/receipt_line_factory.dart';

/// Rend une lecture figée par passe et retient combien de fois on l'appelle.
class _ScriptedRecognizer implements ReceiptLineRecognizer {
  _ScriptedRecognizer(this.passes);

  final List<List<PhysicalLine>> passes;
  final List<Uint8List> received = [];
  bool closed = false;

  @override
  Future<List<PhysicalLine>> recognize(Uint8List imageBytes) async {
    received.add(imageBytes);
    return passes[received.length - 1];
  }

  @override
  Future<void> close() async => closed = true;
}

final Uint8List _photo = Uint8List.fromList([1, 2, 3]);
final Uint8List _enhanced = Uint8List.fromList([4, 5, 6]);

Future<Uint8List> _fakeEnhance(Uint8List bytes) async => _enhanced;

Future<Uint8List> _failingEnhance(Uint8List bytes) async =>
    throw const FormatException('image indéchiffrable');

final List<List<(String, int)>> _verifiedReceipt = [
  [('CARREFOUR', 0)],
  [('PAIN', 0), ('2,00', 20)],
  [('LAIT', 0), ('3,00', 20)],
  [('TOTAL', 0), ('5,00', 20)],
];

final List<List<(String, int)>> _brokenReceipt = [
  [('CARREFOUR', 0)],
  [('PAIN', 0), ('2,00', 20)],
  [('TOTAL', 0), ('5,00', 20)],
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RoleTagger tagger;
  late LabelLinkModel link;
  late LabelSpanModel span;

  setUpAll(() async {
    final taggerAsset = Directory('assets/models')
        .listSync()
        .whereType<File>()
        .map((file) => file.path)
        .firstWhere(
          (path) => RegExp(r'line_roles_v\d+\.json$').hasMatch(path),
          orElse: () => throw StateError(
            'Aucun tagger dans assets/models/ : '
            'lancer ./tool/models/fetch.sh',
          ),
        );
    tagger = RoleTagger(
      LineClassifier.fromJson(
        jsonDecode(await File(taggerAsset).readAsString())
            as Map<String, dynamic>,
      ),
    );

    final linkAsset = Directory('assets/models')
        .listSync()
        .whereType<File>()
        .map((file) => file.path)
        .firstWhere(
          (path) => RegExp(r'label_link_v\d+\.json$').hasMatch(path),
          orElse: () => throw StateError(
            'Aucun modèle de lien dans assets/models/ : '
            'lancer ./tool/models/fetch.sh',
          ),
        );
    link = LabelLinkModel(
      LineClassifier.fromJson(
        jsonDecode(await File(linkAsset).readAsString()) as Map<String, dynamic>,
      ),
    );

    final spanAsset = Directory('assets/models')
        .listSync()
        .whereType<File>()
        .map((file) => file.path)
        .firstWhere(
          (path) => RegExp(r'label_span_v\d+\.json$').hasMatch(path),
          orElse: () => throw StateError(
            'Aucun tagger de spans dans assets/models/ : '
            'lancer ./tool/models/fetch.sh',
          ),
        );
    span = LabelSpanModel(
      LineClassifier.fromJson(
        jsonDecode(await File(spanAsset).readAsString()) as Map<String, dynamic>,
      ),
    );
  });

  LocalReceiptScanner scannerOf(
    _ScriptedRecognizer recognizer, {
    ReceiptImageEnhancer enhance = _fakeEnhance,
  }) {
    return LocalReceiptScanner(
      recognizer: recognizer,
      tagger: tagger,
      link: link,
      span: span,
      enhance: enhance,
    );
  }

  group('LocalReceiptScanner', () {
    test('une somme prouvée dès la passe 1 ne déclenche pas la 2e', () async {
      final recognizer = _ScriptedRecognizer([
        receiptLinesOf(_verifiedReceipt),
      ]);

      final scan = await scannerOf(recognizer).scan(_photo);

      expect(scan.source, ReadSource.pass1);
      expect(scan.verified, isTrue);
      expect(scan.total, 5.0);
      expect([for (final item in scan.items) item.amount], [2.0, 3.0]);
      expect(recognizer.received, [_photo]);
    });

    test('une somme non prouvée relance une passe sur l\'image prétraitée',
        () async {
      final recognizer = _ScriptedRecognizer([
        receiptLinesOf(_brokenReceipt),
        receiptLinesOf(_verifiedReceipt),
      ]);

      final scan = await scannerOf(recognizer).scan(_photo);

      expect(scan.source, ReadSource.retry);
      expect(recognizer.received, [_photo, _enhanced]);
    });

    test('une 2e passe impossible garde la lecture de la première', () async {
      final recognizer = _ScriptedRecognizer([
        receiptLinesOf(_brokenReceipt),
      ]);

      final scan = await scannerOf(
        recognizer,
        enhance: _failingEnhance,
      ).scan(_photo);

      expect(scan.verified, isFalse);
      expect(scan.source, ReadSource.confirm);
      expect([for (final item in scan.items) item.amount], [2.0]);
    });

    test('la 2e passe porte l\'enseigne et la date quand elle a servi',
        () async {
      final recognizer = _ScriptedRecognizer([
        receiptLinesOf([
          [('PAIN', 0), ('2,00', 20)],
          [('TOTAL', 0), ('5,00', 20)],
        ]),
        receiptLinesOf([
          [('CARREFOUR', 0)],
          [('01/08/2026', 0)],
          [('PAIN', 0), ('2,00', 20)],
          [('LAIT', 0), ('3,00', 20)],
          [('TOTAL', 0), ('5,00', 20)],
        ]),
      ]);

      final scan = await scannerOf(recognizer).scan(_photo);

      expect(scan.date, '2026-08-01');
      expect(scan.store, 'CARREFOUR');
    });

    test('un article dont le prix échappe à la regex stricte remonte', () async {
      // La devise collée au montant sortait la ligne du décodeur avant même
      // que le tagger soit consulté : 93 des 100 articles que le corpus
      // d'évaluation perdait. La lecture s'élargit maintenant sur les lignes
      // à qui le tagger donne un rôle porteur de montant.
      final recognizer = _ScriptedRecognizer([
        receiptLinesOf([
          [('CARREFOUR', 0)],
          [('CARRE', 0), ('FOURRE', 6), ('2.15Eur', 20)],
          [('LAIT', 0), ('3,00', 20)],
          [('TOTAL', 0), ('5,15', 20)],
        ]),
      ]);

      final scan = await scannerOf(recognizer).scan(_photo);

      expect(scan.verified, isTrue);
      expect([for (final item in scan.items) item.amount], [2.15, 3.0]);
    });

    test('une photo sans texte est signalée telle quelle', () async {
      final recognizer = _ScriptedRecognizer([const <PhysicalLine>[]]);

      expect(
        () => scannerOf(recognizer).scan(_photo),
        throwsA(isA<ScanUnreadableException>()),
      );
    });

    test('du texte sans aucun article est signalé à part', () async {
      final lines = receiptLinesOf([
        [('MERCI', 0)],
        [('A', 0), ('BIENTOT', 4)],
      ]);
      final recognizer = _ScriptedRecognizer([lines, lines]);

      expect(
        () => scannerOf(recognizer).scan(_photo),
        throwsA(isA<ScanNoItemsException>()),
      );
    });
  });
}
