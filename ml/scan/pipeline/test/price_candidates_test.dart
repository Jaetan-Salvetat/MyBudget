library;

import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

import 'support.dart';

List<double> amounts(String text, {required bool lax}) {
  final tokens = [
    for (final (index, token) in text.split(' ').indexed) (token, index * 6),
  ];
  return [
    for (final candidate in priceCandidates(line(0, tokens), lax: lax))
      roundCents(candidate.price),
  ];
}

List<List<double>> roleRows(List<String> roles) => [
  for (final role in roles)
    [for (final name in roleNames) name == role ? 1.0 : 0.0],
];

void main() {
  group('strict reading', () {
    test('a clean price is read without laxity', () {
      expect(amounts('PAIN 1,20', lax: false), [1.20]);
    });

    test('a glued currency escapes the strict reading', () {
      expect(amounts('CARRE FOURRE T1 2.15Eur', lax: false), isEmpty);
    });

    test('a line the strict reader reaches is never widened', () {
      expect(amounts('PAIN 1,20 2,40Eur', lax: true), [1.20]);
    });
  });

  group('lax reading', () {
    test('currency glued to the price', () {
      expect(amounts('CARRE FOURRE T1 2.15Eur', lax: true), [2.15]);
    });

    test('tax class in parentheses', () {
      expect(amounts('0.858kg x 2.69Eur/kg 2.31(2)', lax: true), [2.31, 2.69]);
    });

    test('trailing junk digit', () {
      expect(amounts('SHEBA SOUPE 160G 2.342', lax: true), [2.34]);
    });

    test('a computed line offers both its amounts', () {
      expect(amounts('OIGNON 2 x 0.85EUR = 1.70EUR', lax: true), [1.70, 0.85]);
    });

    test('a line without any amount offers nothing', () {
      expect(amounts('MERCI DE VOTRE VISITE', lax: true), isEmpty);
    });

    test('a percentage is never an amount', () {
      expect(amounts('(Remise de -14.29%)', lax: true), isEmpty);
      expect(amounts('Remise -15.65% 2.10', lax: true), [2.10]);
    });

    test('the same amount read twice is one candidate', () {
      expect(amounts('PAIN 1.20Eur 1.20Eur', lax: true), [1.20]);
    });
  });

  group('lax ranks follow the tagger', () {
    test('amount bearing roles are lax', () {
      expect(laxRanks(roleRows(['item', 'discount', 'total'])), {0, 1, 2});
    });

    test('roles that carry no amount stay strict', () {
      expect(laxRanks(roleRows(['store', 'date_line', 'noise'])), isEmpty);
    });

    test('only the designated lines widen', () {
      expect(laxRanks(roleRows(['store', 'item', 'noise'])), {1});
    });
  });

  group('priced lines', () {
    List<PhysicalLine> rows() => receiptLines([
      [('CARREFOUR', 0)],
      [('CARRE', 0), ('FOURRE', 6), ('2.15Eur', 20)],
      [('TOTAL', 0), ('2,15', 20)],
    ]);

    test('a line the tagger ignores keeps the strict reading', () {
      expect([for (final p in pricedLines(rows())) p.index], [2]);
    });

    test('a designated line enters with its lax reading', () {
      final lines = pricedLines(rows(), laxRanks: {1});
      expect([for (final p in lines) p.index], [1, 2]);
      expect(lines.first.price, 2.15);
    });

    test('every candidate travels with the line', () {
      final lines = pricedLines(
        receiptLines([
          [
            ('OIGNON', 0),
            ('2', 8),
            ('x', 10),
            ('0.85EUR', 12),
            ('=', 20),
            ('1.70EUR', 22),
          ],
        ]),
        laxRanks: {0},
      );
      expect(lines.first.candidates, [1.70, 0.85]);
    });
  });

  group('extract roles', () {
    test('an item whose price escapes the regex is kept', () {
      final receipt = extractRoles(
        receiptLines([
          [('CARRE', 0), ('FOURRE', 6), ('2.15Eur', 20)],
          [('TOTAL', 0), ('2,15', 20)],
        ]),
        [roleItem, roleTotal],
      );
      expect([for (final item in receipt!.items) item.amount], [2.15]);
    });

    test('a line the tagger calls noise is not read lax', () {
      final receipt = extractRoles(
        receiptLines([
          [('PAIN', 0), ('2,15', 20)],
          [('SIRET', 0), ('1.23Eur', 20)],
        ]),
        [roleItem, 'noise'],
      );
      expect([for (final item in receipt!.items) item.amount], [2.15]);
    });
  });
}
