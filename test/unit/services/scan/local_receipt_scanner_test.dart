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

  late LineClassifier classifier;
  late RoleTagger tagger;
  late LabelLinkModel link;

  setUpAll(() async {
    final asset = Directory('assets/models')
        .listSync()
        .whereType<File>()
        .map((file) => file.path)
        .firstWhere(
          (path) => RegExp(r'line_clf_v\d+\.json$').hasMatch(path),
          orElse: () => throw StateError(
            'Aucun classifieur dans assets/models/ : '
            'lancer ./tool/line_classifier/fetch.sh',
          ),
        );
    final json = await File(asset).readAsString();
    classifier = LineClassifier.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );

    final taggerAsset = Directory('assets/models')
        .listSync()
        .whereType<File>()
        .map((file) => file.path)
        .firstWhere(
          (path) => RegExp(r'line_roles_v\d+\.json$').hasMatch(path),
          orElse: () => throw StateError(
            'Aucun tagger dans assets/models/ : '
            'lancer ./tool/line_classifier/fetch.sh',
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
            'lancer ./tool/line_classifier/fetch.sh',
          ),
        );
    link = LabelLinkModel(
      LineClassifier.fromJson(
        jsonDecode(await File(linkAsset).readAsString()) as Map<String, dynamic>,
      ),
    );
  });

  LocalReceiptScanner scannerOf(
    _ScriptedRecognizer recognizer, {
    ReceiptImageEnhancer enhance = _fakeEnhance,
  }) {
    return LocalReceiptScanner(
      recognizer: recognizer,
      classifier: classifier,
      tagger: tagger,
      link: link,
      enhance: enhance,
    );
  }

  group('LocalReceiptScanner', () {
    test('un ticket que les règles vérifient ne déclenche pas la 2e passe',
        () async {
      final recognizer = _ScriptedRecognizer([
        receiptLinesOf(_verifiedReceipt),
      ]);

      final scan = await scannerOf(recognizer).scan(_photo);

      expect(scan.stage, FlowStage.local);
      expect(scan.verified, isTrue);
      expect(scan.total, 5.0);
      expect([for (final item in scan.items) item.amount], [2.0, 3.0]);
      expect(recognizer.received, [_photo]);
    });

    test('un checksum en échec relance une passe sur l\'image prétraitée',
        () async {
      final recognizer = _ScriptedRecognizer([
        receiptLinesOf(_brokenReceipt),
        receiptLinesOf(_verifiedReceipt),
      ]);

      final scan = await scannerOf(recognizer).scan(_photo);

      expect(scan.stage, FlowStage.localRetry);
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
      expect(scan.stage, FlowStage.confirm);
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
