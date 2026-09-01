import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/gemini_nano_channel.dart';
import 'package:mybudget/core/enums/gemini_nano_failure.dart';
import 'package:mybudget/core/enums/gemini_nano_preference.dart';
import 'package:mybudget/core/services/ai/gemini_nano_service.dart';
import 'package:mybudget/core/services/scan/nano_receipt_reader.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

import '../../../helpers/receipt_line_factory.dart';

class _StubService extends GeminiNanoService {
  _StubService({this.answer, this.failure});

  final String? answer;
  final GeminiNanoFailure? failure;

  String? askedPrompt;
  String? askedSchema;
  GeminiNanoPreference? askedPreference;

  @override
  Future<String> generate({
    required String prompt,
    required String schema,
    required GeminiNanoChannel channel,
    required GeminiNanoPreference preference,
  }) async {
    askedPrompt = prompt;
    askedSchema = schema;
    askedPreference = preference;
    if (failure != null) throw GeminiNanoException(failure!);
    return answer!;
  }
}

final List<PhysicalLine> _lines = receiptLinesOf([
  [('CARREFOUR', 0)],
  [('PAIN', 0), ('2,00', 20)],
  [('LAIT', 0), ('3,00', 20)],
  [('TOTAL', 0), ('5,00', 20)],
]);

String _payload({
  Object? store = 'CARREFOUR',
  Object? date = '2026-08-01',
  Object? total = 5.0,
  List<Object?> items = const [
    {'name': 'PAIN', 'amount': 2.0, 'discount': 0.0},
    {'name': 'LAIT', 'amount': 3.0, 'discount': 0.0},
  ],
}) {
  return jsonEncode({
    'store': store,
    'date': date,
    'total': total,
    'items': items,
  });
}

void main() {
  group('NanoReceiptReader', () {
    test('rend la lecture du modèle sur le schéma ticket', () async {
      final service = _StubService(answer: _payload());

      final scan = await NanoReceiptReader(service: service).read(_lines);

      expect(service.askedSchema, 'receipt');
      expect(service.askedPreference, GeminiNanoPreference.full);
      expect(service.askedPrompt, contains('CARREFOUR'));
      expect(scan!.store, 'CARREFOUR');
      expect(scan.date, '2026-08-01');
      expect(scan.total, 5.0);
      expect([for (final item in scan.items) item.name], ['PAIN', 'LAIT']);
      expect(scan.trace, isEmpty);
    });

    test('une somme d\'articles qui tombe sur le total vaut vérification',
        () async {
      final scan = await NanoReceiptReader(
        service: _StubService(answer: _payload()),
      ).read(_lines);

      expect(scan!.verified, isTrue);
    });

    test('une somme qui ne tombe pas sur le total reste non vérifiée',
        () async {
      final scan = await NanoReceiptReader(
        service: _StubService(answer: _payload(total: 9.0)),
      ).read(_lines);

      expect(scan!.verified, isFalse);
    });

    test('la remise d\'une ligne entre dans le calcul', () async {
      final scan = await NanoReceiptReader(
        service: _StubService(
          answer: _payload(
            total: 4.5,
            items: const [
              {'name': 'PAIN', 'amount': 2.0, 'discount': 0.5},
              {'name': 'LAIT', 'amount': 3.0, 'discount': 0.0},
            ],
          ),
        ),
      ).read(_lines);

      expect(scan!.verified, isTrue);
      expect(scan.items.first.discount, 0.5);
    });

    test('une enseigne ou une date vide n\'est pas retenue', () async {
      final scan = await NanoReceiptReader(
        service: _StubService(answer: _payload(store: '  ', date: '')),
      ).read(_lines);

      expect(scan!.store, isNull);
      expect(scan.date, isNull);
    });

    test('une date hors format est écartée', () async {
      final scan = await NanoReceiptReader(
        service: _StubService(answer: _payload(date: '01/08/2026')),
      ).read(_lines);

      expect(scan!.date, isNull);
    });

    test('un total absent laisse le ticket non vérifié', () async {
      final scan = await NanoReceiptReader(
        service: _StubService(answer: _payload(total: 0)),
      ).read(_lines);

      expect(scan!.total, isNull);
      expect(scan.verified, isFalse);
    });

    test('un article sans libellé ou sans prix est écarté', () async {
      final scan = await NanoReceiptReader(
        service: _StubService(
          answer: _payload(
            items: const [
              {'name': 'PAIN', 'amount': 2.0, 'discount': 0.0},
              {'name': '  ', 'amount': 3.0, 'discount': 0.0},
              {'name': 'LAIT', 'amount': 0.0, 'discount': 0.0},
            ],
          ),
        ),
      ).read(_lines);

      expect([for (final item in scan!.items) item.name], ['PAIN']);
    });

    test('une remise plus grande que le prix est ramenée au prix', () async {
      final scan = await NanoReceiptReader(
        service: _StubService(
          answer: _payload(
            items: const [
              {'name': 'PAIN', 'amount': 2.0, 'discount': 5.0},
            ],
          ),
        ),
      ).read(_lines);

      expect(scan!.items.single.discount, 2.0);
    });

    test('une lecture sans aucun article laisse la main au pipeline local',
        () async {
      final scan = await NanoReceiptReader(
        service: _StubService(answer: _payload(items: const [])),
      ).read(_lines);

      expect(scan, isNull);
    });

    test('une réponse illisible laisse la main au pipeline local', () async {
      final scan = await NanoReceiptReader(
        service: _StubService(answer: 'pas du json'),
      ).read(_lines);

      expect(scan, isNull);
    });

    test('un échec du modèle laisse la main au pipeline local', () async {
      final scan = await NanoReceiptReader(
        service: _StubService(failure: GeminiNanoFailure.quotaExceeded),
      ).read(_lines);

      expect(scan, isNull);
    });

    test('un ticket trop long n\'est pas soumis au modèle', () async {
      final service = _StubService(answer: _payload());
      final scan = await NanoReceiptReader(service: service).read(
        receiptLinesOf([
          for (var index = 0; index < 400; index++)
            [('ARTICLE$index', 0), ('2,00', 20)],
        ]),
      );

      expect(scan, isNull);
      expect(service.askedPrompt, isNull);
    });
  });
}
