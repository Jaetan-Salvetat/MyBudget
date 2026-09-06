import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/constants/receipt_schema.dart';
import 'package:mybudget/core/enums/gemini_nano_channel.dart';
import 'package:mybudget/core/enums/gemini_nano_failure.dart';
import 'package:mybudget/core/enums/gemini_nano_preference.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';
import 'package:mybudget/core/services/ai/gemini_nano_service.dart';
import 'package:mybudget/core/services/scan/local_receipt_scanner.dart';
import 'package:mybudget/core/services/scan/nano_receipt_reader.dart';
import 'package:mybudget/core/services/scan/receipt_line_recognizer.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

import '../../../helpers/receipt_line_factory.dart';

class _ScriptedRecognizer implements ReceiptLineRecognizer {
  _ScriptedRecognizer(this.passes, {this.onRecognize});

  final List<List<PhysicalLine>> passes;
  final void Function()? onRecognize;
  final List<Uint8List> received = [];
  bool closed = false;

  @override
  Future<List<PhysicalLine>> recognize(Uint8List imageBytes) async {
    received.add(imageBytes);
    onRecognize?.call();
    return passes[received.length - 1];
  }

  @override
  Future<void> close() async => closed = true;
}

class _StubNanoService extends GeminiNanoService {
  _StubNanoService({this.sections, this.failure});

  final Map<String, String>? sections;
  final GeminiNanoFailure? failure;

  int calls = 0;
  final List<String> steps = [];

  @override
  Future<void> warmUp(
    GeminiNanoChannel channel,
    GeminiNanoPreference preference,
  ) async => steps.add('warmUp');

  @override
  Future<String> generate({
    required String prompt,
    required String schema,
    required GeminiNanoChannel channel,
    required GeminiNanoPreference preference,
    Uint8List? image,
    double? temperature,
    int? seed,
    bool schemaInPrompt = false,
    bool thinking = false,
    int? candidates,
  }) async {
    calls++;
    steps.add('generate');
    if (failure != null) throw GeminiNanoException(failure!);
    return sections![schema]!;
  }
}

final Map<String, String> _nanoSections = {
  ReceiptSchema.storeName: '{"store":"MONOPRIX"}',
  ReceiptSchema.dateName: '{"date":"2026-08-02"}',
  ReceiptSchema.totalName: '{"total":5.0}',
  ReceiptSchema.itemsName:
      '{"total":5.0,"items":[{"name":"CAFE","amount":5.0,"discount":0.0}]}',
};

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
        jsonDecode(await File(linkAsset).readAsString())
            as Map<String, dynamic>,
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
        jsonDecode(await File(spanAsset).readAsString())
            as Map<String, dynamic>,
      ),
    );
  });

  LocalReceiptScanner scannerOf(
    _ScriptedRecognizer recognizer, {
    ReceiptImageEnhancer enhance = _fakeEnhance,
    StoreClassifier? classifier,
  }) {
    return LocalReceiptScanner(
      recognizer: recognizer,
      tagger: tagger,
      link: link,
      span: span,
      classifier: classifier,
      enhance: enhance,
    );
  }

  group('LocalReceiptScanner', () {
    test('une somme prouvée dès la passe 1 ne déclenche pas la 2e', () async {
      final recognizer = _ScriptedRecognizer([
        receiptLinesOf(_verifiedReceipt),
      ]);

      final scan = await scannerOf(recognizer).scan(_photo);

      expect(scan.verified, isTrue);
      expect(scan.total, 5.0);
      expect([for (final item in scan.items) item.amount], [2.0, 3.0]);
      expect(recognizer.received, [_photo]);
    });

    test(
      'une somme non prouvée relance une passe sur l\'image prétraitée',
      () async {
        final recognizer = _ScriptedRecognizer([
          receiptLinesOf(_brokenReceipt),
          receiptLinesOf(_verifiedReceipt),
        ]);

        final scan = await scannerOf(recognizer).scan(_photo);

        expect(scan.verified, isTrue);
        expect(recognizer.received, [_photo, _enhanced]);
      },
    );

    test('une 2e passe impossible garde la lecture de la première', () async {
      final recognizer = _ScriptedRecognizer([receiptLinesOf(_brokenReceipt)]);

      final scan = await scannerOf(
        recognizer,
        enhance: _failingEnhance,
      ).scan(_photo);

      expect(scan.verified, isFalse);
      expect([for (final item in scan.items) item.amount], [2.0]);
    });

    test(
      'la 2e passe porte l\'enseigne et la date quand elle a servi',
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
      },
    );

    test(
      "le classifieur du ticket nomme l'enseigne avant la ligne désignée",
      () async {
        final recognizer = _ScriptedRecognizer([
          receiptLinesOf([
            [('CARREFOUR', 0)],
            [('PAIN', 0), ('2,00', 20)],
            [('LAIT', 0), ('3,00', 20)],
            [('TOTAL', 0), ('5,00', 20)],
          ]),
        ]);
        final classifier = StoreClassifier(
          classes: [storeClassifierOther, 'Auchan'],
          intercepts: [0.0, 1.0],
          weights: [{}, {}],
        );

        final scan = await scannerOf(
          recognizer,
          classifier: classifier,
        ).scan(_photo);

        expect(scan.store, 'Auchan');
      },
    );

    test(
      'un article dont le prix échappe à la regex stricte remonte',
      () async {
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
      },
    );

    test(
      'Gemini Nano prend la main sur le décodeur local quand il lit',
      () async {
        final service = _StubNanoService(sections: _nanoSections);
        final recognizer = _ScriptedRecognizer([
          receiptLinesOf(_verifiedReceipt),
        ], onRecognize: () => service.steps.add('ocr'));

        final scan = await scannerOf(
          recognizer,
        ).scan(_photo, nano: NanoReceiptReader(service: service));

        expect(service.steps.take(3), ['warmUp', 'ocr', 'generate']);
        expect(scan.store, 'MONOPRIX');
        expect(scan.date, '2026-08-02');
        expect([for (final item in scan.items) item.name], ['CAFE']);
      },
    );

    test('un échec de Gemini Nano rend la main au décodeur local', () async {
      final service = _StubNanoService(
        failure: GeminiNanoFailure.quotaExceeded,
      );
      final recognizer = _ScriptedRecognizer([
        receiptLinesOf(_verifiedReceipt),
      ]);

      final scan = await scannerOf(
        recognizer,
      ).scan(_photo, nano: NanoReceiptReader(service: service));

      expect(service.calls, greaterThan(0));
      expect(scan.verified, isTrue);
      expect([for (final item in scan.items) item.amount], [2.0, 3.0]);
    });

    test('une photo sans texte est signalée telle quelle', () async {
      final recognizer = _ScriptedRecognizer([const <PhysicalLine>[]]);

      expect(
        () => scannerOf(recognizer).scan(_photo),
        throwsA(isA<ScanUnreadableException>()),
      );
    });

    test('sans Gemini Nano, le décodeur local lit le ticket', () async {
      final recognizer = _ScriptedRecognizer([
        receiptLinesOf(_verifiedReceipt),
      ]);

      final scan = await scannerOf(recognizer).scan(_photo);

      expect(scan.verified, isTrue);
      expect(recognizer.received, [_photo]);
    });

    test('un échec de Gemini Nano rend la main au décodeur local', () async {
      final service = _StubNanoService(
        failure: GeminiNanoFailure.quotaExceeded,
      );
      final recognizer = _ScriptedRecognizer([
        receiptLinesOf(_verifiedReceipt),
      ]);

      final scan = await scannerOf(
        recognizer,
      ).scan(_photo, nano: NanoReceiptReader(service: service));

      expect(scan.verified, isTrue);
      expect([for (final item in scan.items) item.amount], [2.0, 3.0]);
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
