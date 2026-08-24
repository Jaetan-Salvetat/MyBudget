import 'dart:math' as math;

import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

const double lineHeight = 30.0;
const double charWidth = 14.0;

Word word(String text, int column, int row) {
  final left = column * charWidth;
  final top = row * (lineHeight + 8);
  return Word(
    text: text,
    left: left,
    top: top,
    right: left + text.length * charWidth,
    bottom: top + lineHeight,
    confidence: 0.9,
  );
}

PhysicalLine line(int row, List<(String, int)> tokens) {
  return PhysicalLine(
    words: [for (final (text, column) in tokens) word(text, column, row)],
  );
}

List<PhysicalLine> receiptLines(List<List<(String, int)>> rows) {
  return [for (final (index, tokens) in rows.indexed) line(index, tokens)];
}

List<(String, double)> namedAmounts(ExtractedReceipt receipt) =>
    [for (final item in receipt.items) (item.name, item.amount)];

void main() {
  group('parsePrice', () {
    test('comma decimal', () {
      expect(parsePrice('12,50'), 12.50);
    });

    test('dot decimal', () {
      expect(parsePrice('3.99'), 3.99);
    });

    test('negative', () {
      expect(parsePrice('-0,50'), -0.50);
    });

    test('euro suffix', () {
      expect(parsePrice('5,16€'), 5.16);
    });

    test('leader dots', () {
      expect(parsePrice('....14,90'), 14.90);
    });

    test('mutilated euro letters', () {
      expect(parsePrice('e3.16e'), 3.16);
    });

    test('glyph confusion', () {
      expect(parsePrice('2.I8'), 2.18);
    });

    test('plain word is not a price', () {
      expect(parsePrice('PAIN'), isNull);
    });

    test('integer is not a price', () {
      expect(parsePrice('1234'), isNull);
    });

    test('version number is not a price', () {
      expect(parsePrice('V.2.16.0.70'), isNull);
    });
  });

  group('extract', () {
    test('simple items', () {
      final lines = receiptLines([
        [('CARREFOUR', 10)],
        [('LAIT', 0), ('ENTIER', 5), ('1,20', 38)],
        [('PAIN', 0), ('2,50', 38)],
        [('TOTAL', 0), ('3,70', 38)],
      ]);
      final result = extract(lines);
      expect(namedAmounts(result), [
        ('LAIT ENTIER', 1.20),
        ('PAIN', 2.50),
      ]);
      expect(result.total, 3.70);
      expect(result.checksumOk, isTrue);
    });

    test('discount attaches to previous item', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('CHIPS', 0), ('2,00', 38)],
        [('REMISE', 2), ('FID.', 9), ('-0,50', 37)],
        [('TOTAL', 0), ('1,50', 38)],
      ]);
      final result = extract(lines);
      expect(result.items.first.discount, 0.50);
      expect(result.checksumOk, isTrue);
    });

    test('quantity on second line', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('CAFE', 0), ('MOULU', 5)],
        [('3', 2), ('X', 4), ('3,40', 6), ('10,20', 37)],
        [('TOTAL', 0), ('10,20', 37)],
      ]);
      final result = extract(lines);
      expect(namedAmounts(result), [('CAFE MOULU', 10.20)]);
    });

    test('total and payment are not items', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('PAIN', 0), ('2,50', 38)],
        [('TOTAL', 0), ('A', 6), ('PAYER', 8), ('2,50', 38)],
        [('CB', 0), ('EMV', 3), ('2,50', 38)],
        [('ESPECES', 0), ('5,00', 38)],
        [('RENDU', 0), ('2,50', 38)],
      ]);
      final result = extract(lines);
      expect(result.items, hasLength(1));
      expect(result.total, 2.50);
    });

    test('split total recovered', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('PAIN', 0), ('54,50', 37)],
        [('Total', 0), (':', 6), ('54', 37), ('50', 40)],
      ]);
      expect(extract(lines).total, 54.50);
    });

    test('phone number is not a price', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('Fax.:', 0), ('033', 6), ('853', 10), ('67', 14), ('19', 17)],
        [('PAIN', 0), ('2,50', 38)],
      ]);
      expect(namedAmounts(extract(lines)), [('PAIN', 2.50)]);
    });

    test('date with split digits', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('LE', 0), ('15/o9/202', 3), ('6', 13), ('A', 15), ('14:06', 17)],
      ]);
      expect(extract(lines).date, '2026-09-15');
    });

    test('date with dots', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('30.07.2007/13:29:17', 10)],
      ]);
      expect(extract(lines).date, '2007-07-30');
    });

    test('promotion in name is still an item', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('Salades', 0), ('x2', 8), ('(promotion)', 11), ('1,40', 38)],
        [('TOTAL', 0), ('1,40', 38)],
      ]);
      final result = extract(lines);
      expect(result.items.first.amount, 1.40);
      expect(result.items.first.discount, 0.0);
    });

    test('quantity prefix stripped from name', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('1', 0), ('WELSH', 2), ('10.20', 20), ('10.20', 37)],
      ]);
      final result = extract(lines);
      expect(result.items.first.name, 'WELSH');
      expect(result.items.first.amount, 10.20);
    });
  });

  group('mergePriceFragments', () {
    test('split discount merged', () {
      final source = line(0, [('REMISE', 2), ('-1,', 30), ('00', 33)]);
      final merged = mergePriceFragments(source);
      expect([for (final w in merged.words) w.text], ['REMISE', '-1,00']);
    });

    test('distant fragments untouched', () {
      final source = line(0, [('REMISE', 2), ('-1,', 10), ('00', 33)]);
      final merged = mergePriceFragments(source);
      expect(
        [for (final w in merged.words) w.text],
        ['REMISE', '-1,', '00'],
      );
    });
  });

  group('deskew', () {
    test('rotated words regroup on same line', () {
      final left = word('PAIN', 0, 0);
      final right = word('2,50', 38, 0);
      const angle = 4.0;
      final radians = angle * math.pi / 180;

      Word rotate(Word w) {
        final cx = (w.left + w.right) / 2;
        final cy = (w.top + w.bottom) / 2;
        final rx = cx * math.cos(radians) - cy * math.sin(radians);
        final ry = cx * math.sin(radians) + cy * math.cos(radians);
        return Word(
          text: w.text,
          left: rx - (w.right - w.left) / 2,
          top: ry - (w.bottom - w.top) / 2,
          right: rx + (w.right - w.left) / 2,
          bottom: ry + (w.bottom - w.top) / 2,
          confidence: w.confidence,
        );
      }

      final tilted = [rotate(left), rotate(right)];
      expect(clusterLines(tilted), hasLength(2));
      expect(clusterLines(deskewWords(tilted, angle)), hasLength(1));
    });
  });

  group('change due', () {
    test('a rendre line is not an item', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('PAIN', 0), ('2,50', 38)],
        [('ESPECES', 0), ('5,00', 38)],
        [('A', 0), ('RENDRE', 2), ('EUR', 20), ('2,50', 38)],
      ]);
      expect(namedAmounts(extract(lines)), [('PAIN', 2.50)]);
    });

    test('a rendre zero is not an item', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('PAIN', 0), ('2,50', 38)],
        [('A', 0), ('RENDRE', 2), ('EUR', 20), ('0,00', 38)],
        [('TOTAL', 0), ('2,50', 38)],
      ]);
      final result = extract(lines);
      expect(namedAmounts(result), [('PAIN', 2.50)]);
      expect(result.checksumOk, isTrue);
    });
  });

  group('diacritics fold', () {
    test('ocr caron in TTC still matches stop word', () {
      final lines = receiptLines([
        [('STORE', 10)],
        [('PAIN', 0), ('2,50', 38)],
        [('PRIX', 0), ('TŤC', 6), ('euros', 12), ('19,40', 37)],
        [('TOTAL', 0), ('2,50', 38)],
      ]);
      final result = extract(lines);
      expect(namedAmounts(result), [('PAIN', 2.50)]);
    });
  });
}
