library;

import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

import 'support.dart';

ExtractedReceipt? receiptOf(
  List<List<(String, int)>> rows,
  List<String> roles,
) {
  final lines = [
    for (final line in receiptLines(rows)) mergePriceFragments(line),
  ];
  return extractRoles(lines, roles);
}

void main() {
  test('articles et remise', () {
    final receipt = receiptOf(
      [
        [('CARREFOUR', 10)],
        [('LAIT', 0), ('ENTIER', 5), ('1,20', 38)],
        [('REMISE', 0), ('-0,20', 38)],
        [('TOTAL', 0), ('1,00', 38)],
      ],
      ['noise', 'item', 'discount', 'total'],
    );
    expect(receipt, isNotNull);
    expect(
      [for (final i in receipt!.items) (i.name, i.amount, i.discount)],
      [('LAIT ENTIER', 1.20, 0.20)],
    );
    expect(receipt.total, 1.00);
    expect(receipt.checksumOk, isTrue);
  });

  test('une ligne à prix que le tagger refuse n\'est pas un article', () {
    final receipt = receiptOf(
      [
        [('MAXI', 10)],
        [('1', 8), ('x', 11), ('16,99', 24), ('EUR', 32)],
        [('PREM', 0), ('Litiere', 6), ('16,99', 38)],
        [('TOTAL', 0), ('16,99', 38)],
      ],
      ['noise', 'noise', 'item', 'total'],
    );
    expect(receipt, isNotNull);
    expect([for (final i in receipt!.items) i.amount], [16.99]);
    expect(receipt.checksumOk, isTrue);
  });

  test('un libellé désigné prime sur la zone de gauche', () {
    final receipt = receiptOf(
      [
        [('POIRE', 0), ('CONFERENCE', 6)],
        [('0,792', 0), ('kg', 6), ('2,65', 12), ('2,10', 38)],
        [('TOTAL', 0), ('2,10', 38)],
      ],
      ['item_label', 'item', 'total'],
    );
    expect(receipt!.items.single.name, 'POIRE CONFERENCE');
  });

  test('un montant négatif se déduit du précédent quoi qu\'en dise le rôle', () {
    final receipt = receiptOf(
      [
        [('LAIT', 0), ('1,20', 38)],
        [('AVANTAGE', 0), ('-0,20', 38)],
        [('TOTAL', 0), ('1,00', 38)],
      ],
      ['item', 'item', 'total'],
    );
    expect(receipt!.items.single.discount, 0.20);
    expect(receipt.checksumOk, isTrue);
  });

  test('sans article, pas de reçu', () {
    expect(
      receiptOf(
        [
          [('MERCI', 0)],
          [('TOTAL', 0), ('1,00', 38)],
        ],
        ['noise', 'total'],
      ),
      isNull,
    );
  });
}
