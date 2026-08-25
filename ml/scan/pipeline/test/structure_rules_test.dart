import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('damaged prices', () {
    test('semicolon decimal separator', () {
      expect(parsePrice('17;00'), 17.00);
    });

    test('leading colon stripped', () {
      expect(parsePrice(':17,00'), 17.00);
    });

    test('total line price with trailing junk digit', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('SALADE', 0), ('7,07', 38)],
        [('TOTAL', 0), ('A', 6), ('PAYER', 8), ('7.074', 37)],
      ]);
      expect(extract(lines).total, 7.07);
    });

    test('item line keeps three decimals unparsed', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('SALADE', 0), ('4.236', 38)],
        [('TOTAL', 0), ('4,23', 38)],
      ]);
      expect(extract(lines).items, isEmpty);
    });

    test('split total with separator on decimals', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('VIN', 0), ('17,00', 38)],
        [('TOTAL', 0), ('TTC', 6), ('17', 36), (',00', 38)],
      ]);
      expect(extract(lines).total, 17.00);
    });
  });

  group('fuzzy total', () {
    test('total with one damaged glyph', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('CLOU', 0), ('32,17', 38)],
        [("TO'AL", 0), ('Euro', 6), ('32.17', 38)],
      ]);
      final result = extract(lines);
      expect(result.total, 32.17);
      expect(result.checksumOk, isTrue);
    });

    test('total missing first letter', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('VIN', 0), ('14,50', 38)],
        [('OTAL', 0), ('REGLEMENT', 5), ('14,50', 38)],
      ]);
      expect(extract(lines).total, 14.50);
    });

    test('unrelated word is not a total', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('HOTEL', 0), ('DU', 6), ('PORT', 9), ('80,00', 38)],
        [('TOTAL', 0), ('80,00', 38)],
      ]);
      expect([for (final i in extract(lines).items) i.amount], [80.00]);
    });

    test('levenshtein', () {
      expect(levenshtein("TO'AL", 'TOTAL'), 1);
      expect(levenshtein('TOTAUX', 'TOTAL'), 2);
      expect(containsTotal('Tota TTC 8.96'), isTrue);
      expect(containsTotal('Totaux: 0.56 10.04'), isFalse);
    });
  });

  group('subtotal abbreviation', () {
    test('S/TOT is a subtotal never the total', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('CAFE', 0), ('4,35', 38)],
        [('S/TOT', 0), ('18.47', 38)],
        [('TOTAL', 0), ('4,35', 38)],
      ]);
      final result = extract(lines);
      expect(result.total, 4.35);
      expect(result.subtotal, 18.47);
    });

    test('S/TOT alone does not become the total', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('CAFE', 0), ('4,35', 38)],
        [('S/TOT', 0), ('18.47', 38)],
      ]);
      expect(extract(lines).total, isNull);
    });
  });

  group('card brand payments', () {
    test('visa line is a payment', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('JEU', 0), ('38,96', 38)],
        [('Visa', 0), ('38.96', 38)],
      ]);
      final result = extract(lines);
      expect(result.payment, 38.96);
      expect(result.items.length, 1);
    });

    test('contactless line is a payment', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('JEU', 0), ('7,07', 38)],
        [('C8', 0), ('EMV', 3), ('SANS', 7), ('CONTACT', 12), ('7.07', 38)],
      ]);
      final result = extract(lines);
      expect(result.payment, 7.07);
      expect(result.items.length, 1);
    });
  });

  group('tax lexicon', () {
    test('us tax line is not an item', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('BURGER', 0), ('8,95', 38)],
        [('TAX', 0), ('0,74', 38)],
        [('TOTAL', 0), ('9,69', 38)],
      ]);
      expect([for (final i in extract(lines).items) i.amount], [8.95]);
    });
  });

  group('zero amount lines', () {
    test('zero amount line is not an item', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('VESTE', 0), ('34,99', 38)],
        [('Info', 0), ('0,00', 38)],
        [('TOTAL', 0), ('34,99', 38)],
      ]);
      expect([for (final i in extract(lines).items) i.amount], [34.99]);
    });
  });

  group('verifiedTotal', () {
    ExtractedReceipt build({
      double? total,
      double? subtotal,
      double? payment,
      double? tvaTtcSum,
      int? printedCount,
    }) {
      return ExtractedReceipt(
        store: null,
        date: null,
        total: total,
        subtotal: subtotal,
        payment: payment,
        items: [ExtractedItem(name: 'A', amount: 2.0, discount: 0.0)],
        tvaTtcSum: tvaTtcSum,
        printedCount: printedCount,
      );
    }

    test('read total that matches', () {
      expect(build(total: 2.0).verifiedTotal, 2.0);
    });

    test('payment with count overrides a misread total', () {
      final receipt = build(total: 3.44, payment: 2.0, printedCount: 1);
      expect(receipt.checksumOk, isTrue);
      expect(receipt.verifiedTotal, 2.0);
    });

    test('tva table sum when total unreadable', () {
      expect(build(tvaTtcSum: 2.0).verifiedTotal, 2.0);
    });

    test('none when nothing matches', () {
      expect(build(total: 9.0).verifiedTotal, isNull);
    });
  });
}
