import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/constants/receipt_schema.dart';
import 'package:mybudget/core/enums/gemini_nano_channel.dart';
import 'package:mybudget/core/enums/gemini_nano_failure.dart';
import 'package:mybudget/core/enums/gemini_nano_preference.dart';
import 'package:mybudget/data/service/ai/gemini_nano_service.dart';
import 'package:mybudget/data/service/scan/local_receipt_scan.dart';
import 'package:mybudget/data/service/scan/nano_receipt_reader.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

import '../../../../helpers/receipt_line_factory.dart';

typedef _Call = ({String schema, String prompt, bool thinking});

class _StubService extends GeminiNanoService {
  _StubService({required this.sections, this.attempts = const []});

  /// Réponse par schéma, pour les sections à un seul appel.
  final Map<String, Object> sections;

  /// Réponses successives de la section articles, un tirage par entrée.
  final List<Object> attempts;

  final List<_Call> calls = [];
  int _attempt = 0;

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
    calls.add((schema: schema, prompt: prompt, thinking: thinking));

    final Object? answer;
    if (schema == ReceiptSchema.itemsName) {
      answer = _attempt < attempts.length ? attempts[_attempt++] : null;
    } else {
      answer = sections[schema];
    }

    if (answer is GeminiNanoFailure) throw GeminiNanoException(answer);
    if (answer is! String) {
      throw const GeminiNanoException(GeminiNanoFailure.unknown);
    }
    return answer;
  }
}

final Uint8List _photo = Uint8List.fromList([1, 2, 3]);

final List<PhysicalLine> _lines = receiptLinesOf([
  [('CARREFOUR', 0)],
  [('PAIN', 0), ('2,00', 20)],
  [('LAIT', 0), ('3,00', 20)],
  [('TOTAL', 0), ('5,00', 20)],
]);

const String _pairOfItems =
    '{"total":5.0,"items":[{"name":"PAIN","amount":2.0,"discount":0.0},'
    '{"name":"LAIT","amount":3.0,"discount":0.0}]}';

const String _oneItem =
    '{"total":2.0,"items":[{"name":"PAIN","amount":2.0,"discount":0.0}]}';

Map<String, Object> _sections({
  Object store = '{"store":"CARREFOUR CITY"}',
  Object date = '{"date":"2017-02-24"}',
  Object total = '{"total":5.0}',
}) => {
  ReceiptSchema.storeName: store,
  ReceiptSchema.dateName: date,
  ReceiptSchema.totalName: total,
};

void main() {
  group('NanoReceiptReader', () {
    test(
      'une section par donnée, dans l\'ordre, photo et texte à chaque fois',
      () async {
        final service = _StubService(
          sections: _sections(),
          attempts: const [_pairOfItems],
        );

        final scan = await NanoReceiptReader(
          service: service,
        ).read(_photo, _lines);

        expect(
          [for (final call in service.calls) call.schema],
          [
            ReceiptSchema.totalName,
            ReceiptSchema.storeName,
            ReceiptSchema.dateName,
            ReceiptSchema.itemsName,
          ],
          reason: 'le total est lu en premier : c\'est lui que l\'écran pose',
        );
        expect(
          [for (final call in service.calls) call.prompt],
          everyElement(contains('## Transcription OCR')),
          reason: 'chaque section reçoit la transcription OCR',
        );
        expect(scan, isNotNull);
        expect(scan!.store, 'CARREFOUR CITY');
        expect(scan.date, '2017-02-24');
        expect(scan.total, 5.0);
        expect([for (final item in scan.items) item.name], ['PAIN', 'LAIT']);
        expect(scan.verified, isTrue);
      },
    );

    test('chaque section est rendue dès qu\'elle tombe', () async {
      final service = _StubService(
        sections: _sections(),
        attempts: const [_pairOfItems],
      );
      final parts = <ReceiptReadPart>[];

      await NanoReceiptReader(
        service: service,
      ).read(_photo, _lines, onPart: parts.add);

      expect(parts.length, 3);
      expect(parts[0].total, 5.0);
      expect(parts[1].store, 'CARREFOUR CITY');
      expect(parts[2].date, '2017-02-24');
    });

    test('une section manquée n\'est pas rendue', () async {
      final service = _StubService(
        sections: _sections(store: GeminiNanoFailure.unknown),
        attempts: const [_pairOfItems],
      );
      final parts = <ReceiptReadPart>[];

      await NanoReceiptReader(
        service: service,
      ).read(_photo, _lines, onPart: parts.add);

      expect([for (final part in parts) part.store], everyElement(isNull));
      expect(parts.length, 2);
    });

    test('l\'enseigne et la date raisonnent, le total non', () async {
      final service = _StubService(
        sections: _sections(),
        attempts: const [_pairOfItems],
      );

      await NanoReceiptReader(service: service).read(_photo, _lines);

      final thinking = {
        for (final call in service.calls) call.schema: call.thinking,
      };
      expect(thinking[ReceiptSchema.storeName], isTrue);
      expect(thinking[ReceiptSchema.dateName], isTrue);
      expect(thinking[ReceiptSchema.totalName], isFalse);
    });

    test('un tirage dont la somme rate le total en relance un autre', () async {
      final service = _StubService(
        sections: _sections(),
        attempts: const [_oneItem, _pairOfItems],
      );

      final scan = await NanoReceiptReader(
        service: service,
      ).read(_photo, _lines);

      expect(
        service.calls.where((call) => call.schema == ReceiptSchema.itemsName),
        hasLength(2),
      );
      expect([for (final item in scan!.items) item.name], ['PAIN', 'LAIT']);
      expect(scan.verified, isTrue);
    });

    test('la photo seule sert de dernier recours pour les articles', () async {
      final service = _StubService(
        sections: _sections(),
        attempts: const [_oneItem, _oneItem, _pairOfItems],
      );

      final scan = await NanoReceiptReader(
        service: service,
      ).read(_photo, _lines);

      final items = service.calls
          .where((call) => call.schema == ReceiptSchema.itemsName)
          .toList();
      expect(items, hasLength(3));
      expect(
        items.last.prompt,
        isNot(contains('## Transcription OCR')),
        reason: 'le troisième tirage ne voit plus que la photo',
      );
      expect(scan!.verified, isTrue);
    });

    test(
      'aucun tirage prouvé garde le premier lu, sans le déclarer vérifié',
      () async {
        final service = _StubService(
          sections: _sections(),
          attempts: const [_oneItem, _oneItem, _oneItem, _oneItem],
        );

        final scan = await NanoReceiptReader(
          service: service,
        ).read(_photo, _lines);

        expect(scan, isNotNull);
        expect(scan!.verified, isFalse);
        expect([for (final item in scan.items) item.name], ['PAIN']);
        expect(
          service.calls.where((call) => call.schema == ReceiptSchema.itemsName),
          hasLength(4),
        );
      },
    );

    test('sans le moindre article il n\'y a pas de lecture', () async {
      final service = _StubService(
        sections: _sections(),
        attempts: const [GeminiNanoFailure.policyRefused],
      );

      expect(
        await NanoReceiptReader(service: service).read(_photo, _lines),
        isNull,
      );
    });

    test('une section d\'en-tête perdue laisse le reste debout', () async {
      final service = _StubService(
        sections: _sections(
          store: GeminiNanoFailure.policyRefused,
          date: 'pas du json',
        ),
        attempts: const [_pairOfItems],
      );

      final scan = await NanoReceiptReader(
        service: service,
      ).read(_photo, _lines);

      expect(scan, isNotNull);
      expect(scan!.store, isNull);
      expect(scan.date, isNull);
      expect(scan.items, hasLength(2));
    });

    test('une date au format français est rendue en ISO', () async {
      final service = _StubService(
        sections: _sections(date: '{"date":"24/02/2017"}'),
        attempts: const [_pairOfItems],
      );

      final scan = await NanoReceiptReader(
        service: service,
      ).read(_photo, _lines);

      expect(scan?.date, '2017-02-24');
    });

    test('une date illisible reste écartée', () async {
      final service = _StubService(
        sections: _sections(date: '{"date":"hier"}'),
        attempts: const [_pairOfItems],
      );

      final scan = await NanoReceiptReader(
        service: service,
      ).read(_photo, _lines);

      expect(scan?.date, isNull);
    });

    test('un ticket illisible par l\'OCR ne part pas au modèle', () async {
      final service = _StubService(sections: _sections());

      final scan = await NanoReceiptReader(
        service: service,
      ).read(_photo, const <PhysicalLine>[]);

      expect(scan, isNull);
      expect(service.calls, isEmpty);
    });

    test('un ticket trop long pour la fenêtre ne part pas', () async {
      final service = _StubService(sections: _sections());
      final long = receiptLinesOf([
        for (var index = 0; index < 400; index++)
          [('ARTICLE$index', 0), ('2,00', 20)],
      ]);

      expect(
        await NanoReceiptReader(service: service).read(_photo, long),
        isNull,
      );
      expect(service.calls, isEmpty);
    });
  });
}
