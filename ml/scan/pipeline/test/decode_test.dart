import 'dart:math' as math;

import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

import 'support.dart';

LineOptions options(int cents, double item, double discount, double ignore) {
  return LineOptions(
    cents: cents,
    logProbs: {
      labelItem: math.log(item),
      labelDiscount: math.log(discount),
      labelIgnore: math.log(ignore),
    },
  );
}

PricedLine pricedAt(int index, double price, {String label = 'ART'}) {
  final word = Word(
    text: price.toStringAsFixed(2),
    left: 300,
    top: index * 40.0,
    right: 350,
    bottom: index * 40.0 + 20,
    confidence: 0.9,
  );
  final name = Word(
    text: label,
    left: 0,
    top: index * 40.0,
    right: 60,
    bottom: index * 40.0 + 20,
    confidence: 0.9,
  );
  return PricedLine(
    index: index,
    line: PhysicalLine(words: [name, word]),
    price: price,
    word: word,
  );
}

const List<double> itemP = [0.99, 0.0, 0.0, 0.0, 0.01];
const List<double> ignoreP = [0.01, 0.0, 0.0, 0.0, 0.99];
const List<double> totalP = [0.0, 0.0, 0.99, 0.0, 0.01];
const List<double> paymentP = [0.0, 0.0, 0.0, 0.99, 0.01];

List<PricedLine> priced2(List<List<(String, int)>> rows) {
  final lines = priced(rows);
  assert(lines.length == rows.length, 'every row must carry a price');
  return lines;
}

void main() {
  group('bestAssignment', () {
    test('argmax when it already sums to target', () {
      final lines = [
        options(200, 0.9, 0.05, 0.05),
        options(300, 0.9, 0.05, 0.05),
      ];
      expect(bestAssignment(lines, 500), [labelItem, labelItem]);
    });

    test('drops least confident line to hit target', () {
      final lines = [
        options(200, 0.9, 0.05, 0.05),
        options(300, 0.9, 0.05, 0.05),
        options(435, 0.5, 0.05, 0.45),
      ];
      expect(bestAssignment(lines, 500), [labelItem, labelItem, labelIgnore]);
    });

    test('promotes ignored line when needed', () {
      final lines = [
        options(200, 0.9, 0.05, 0.05),
        options(300, 0.4, 0.05, 0.55),
      ];
      expect(bestAssignment(lines, 500), [labelItem, labelItem]);
    });

    test('discount subtracts', () {
      final lines = [
        options(1000, 0.9, 0.05, 0.05),
        options(-250, 0.05, 0.9, 0.05),
      ];
      expect(bestAssignment(lines, 750), [labelItem, labelDiscount]);
    });

    test('positive discount line subtracts too', () {
      final lines = [
        options(1000, 0.9, 0.05, 0.05),
        options(250, 0.3, 0.6, 0.1),
      ];
      expect(bestAssignment(lines, 750), [labelItem, labelDiscount]);
    });

    test('no solution returns null', () {
      final lines = [
        options(200, 0.9, 0.05, 0.05),
        options(300, 0.9, 0.05, 0.05),
      ];
      expect(bestAssignment(lines, 999), isNull);
    });

    test('prefers most probable among solutions', () {
      final lines = [
        options(500, 0.6, 0.05, 0.35),
        options(200, 0.9, 0.05, 0.05),
        options(300, 0.9, 0.05, 0.05),
      ];
      expect(bestAssignment(lines, 500), [labelIgnore, labelItem, labelItem]);
    });

    test('label below floor is forbidden', () {
      final lines = [
        options(200, 0.9, 0.05, 0.05),
        options(300, 0.001, 0.001, 0.998),
      ];
      expect(bestAssignment(lines, 500, minProb: 0.01), isNull);
    });

    test('empty lines', () {
      expect(bestAssignment([], 0), isEmpty);
    });
  });

  group('line options', () {
    List<LineOptions> build(
      List<double> prices,
      int cutoffRank, {
      Set<int> forcedIgnore = const {},
      int? referenceRank,
    }) {
      final lines = [for (final (i, p) in prices.indexed) pricedAt(i, p)];
      final probas = [
        for (var i = 0; i < prices.length; i++) [0.8, 0.1, 0.05, 0.0, 0.05],
      ];
      return lineOptions(
        lines,
        probas,
        cutoffRank,
        forcedIgnore: forcedIgnore,
        referenceRank: referenceRank,
      );
    }

    test('zero cent line is never an item', () {
      final opts = build([0.0, 2.0], 5);
      expect(opts[0].logProbs.keys, [labelIgnore]);
      expect(opts[1].logProbs.containsKey(labelItem), isTrue);
    });

    test('lines after cutoff are forced to ignore', () {
      final opts = build([2.0, 3.0, 5.0, 1.5], 2, referenceRank: 2);
      expect(opts[0].logProbs.containsKey(labelItem), isTrue);
      expect(opts[1].logProbs.containsKey(labelItem), isTrue);
      expect(opts[2].logProbs.keys, [labelIgnore]);
      expect(opts[3].logProbs.keys, [labelIgnore]);
    });

    test('negative price cannot be an item', () {
      final opts = build([2.0, -1.0, 5.0], 2);
      expect(opts[1].logProbs.containsKey(labelItem), isFalse);
      expect(opts[1].logProbs.containsKey(labelDiscount), isTrue);
    });

    test('forced ignore rank has no other option', () {
      final opts = build([2.0, 3.0, 5.0], 2, forcedIgnore: {1});
      expect(opts[1].logProbs.keys, [labelIgnore]);
    });
  });

  group('references', () {
    test('virtual tax reference verifies items without total line', () {
      final lines = priced2([
        [('CAFE', 0), ('4.50', 38)],
        [('CHOCOLAT', 0), ('5.80', 38)],
        [('TVA', 0), ('10%', 4), ('0.94', 38)],
        [('HT', 0), ('9.36', 38)],
        [('10.30', 38)],
      ]);
      final probas = [
        itemP,
        itemP,
        ignoreP,
        [0.9, 0.0, 0.0, 0.0, 0.1],
        [0.0, 0.0, 0.02, 0.0, 0.98],
      ];
      final hypothesis = decodeConstrained(lines, probas)!;
      expect(hypothesis.referenceCents, 1030);
      expect(hypothesis.labels, [
        labelItem,
        labelItem,
        labelIgnore,
        labelIgnore,
        labelIgnore,
      ]);
    });

    test('subtotal before a discount is never the reference', () {
      final lines = priced2([
        [('CAFE', 0), ('4,35', 38)],
        [('14.12', 38)],
        [('S/TOT', 0), ('18.47', 38)],
        [('SUB', 0), ('ORANGE', 4), ('-14.12', 37)],
        [('TOTAL', 0), ('4,35', 38)],
      ]);
      final probas = [
        itemP,
        [0.85, 0.0, 0.0, 0.0, 0.15],
        [0.0, 0.0, 0.96, 0.0, 0.04],
        [0.0, 0.97, 0.0, 0.0, 0.03],
        totalP,
      ];
      final hypothesis = decodeConstrained(lines, probas)!;
      expect(hypothesis.referenceCents, 435);
      expect(hypothesis.labels[2], labelIgnore);
      expect(hypothesis.labels[4], labelTotal);
    });

    test('section total is never the reference', () {
      final lines = priced2([
        [('PAIN', 0), ('0,99', 38)],
        [('TOTAL', 0), ('ALIMENTAIRE', 6), ('0,99', 38)],
        [('SAVON', 0), ('2,00', 38)],
        [('TOTAL', 0), ('A', 6), ('PAYER', 8), ('2,99', 38)],
      ]);
      final probas = [
        itemP,
        [0.0, 0.0, 0.6, 0.0, 0.4],
        itemP,
        totalP,
      ];
      final hypothesis = decodeConstrained(lines, probas)!;
      expect(hypothesis.referenceCents, 299);
      expect(hypothesis.labels, [
        labelItem,
        labelIgnore,
        labelItem,
        labelTotal,
      ]);
    });

    test('summary discount is ignored', () {
      final lines = priced2([
        [('LIT', 0), ('55,00', 38)],
        [('Nouveau', 0), ('prix', 8), ('49,90', 14), ('-5,10', 37)],
        [('REMISE', 0), ('TOTALE', 7), ('-5,10', 37)],
        [('TOTAL', 0), ('49,90', 38)],
      ]);
      final probas = [
        itemP,
        [0.05, 0.9, 0.0, 0.0, 0.05],
        [0.0, 0.99, 0.0, 0.0, 0.01],
        totalP,
      ];
      final hypothesis = decodeConstrained(lines, probas)!;
      expect(hypothesis.labels, [
        labelItem,
        labelDiscount,
        labelIgnore,
        labelTotal,
      ]);
    });

    test('payment minus change verifies items', () {
      final lines = priced2([
        [('Soupe', 0), ('7,98', 38)],
        [('Soupe', 0), ('7,98', 38)],
        [('Espèces', 0), ('20,00', 38)],
        [('Rendu', 0), ('Espèces', 6), ('4,04', 38)],
      ]);
      final probas = [
        itemP,
        itemP,
        [0.0, 0.0, 0.0, 0.9, 0.1],
        ignoreP,
      ];
      final hypothesis = decodeConstrained(lines, probas)!;
      expect(hypothesis.referenceCents, 1596);
      expect(hypothesis.labels, [
        labelItem,
        labelItem,
        labelIgnore,
        labelIgnore,
      ]);
    });

    test('concordant sources outrank a lone classifier total', () {
      final lines = priced2([
        [('VIN', 0), ('17,00', 38)],
        [('3,00', 38)],
        [('TOTAL', 0), ('TTC', 6), ('20,00', 38)],
        [('TOTAL', 0), ('17,00', 38)],
        [('TVA', 0), ('10%', 4), ('1,55', 38)],
        [('HT', 0), ('15,45', 38)],
      ]);
      final probas = [
        itemP,
        [0.5, 0.0, 0.0, 0.0, 0.5],
        [0.0, 0.0, 0.9, 0.0, 0.1],
        [0.0, 0.0, 0.6, 0.0, 0.4],
        ignoreP,
        ignoreP,
      ];
      final hypothesis = decodeConstrained(lines, probas)!;
      expect(hypothesis.referenceCents, 1700);
      expect(hypothesis.labels[1], labelIgnore);
    });

    test('bare section total can be ignored despite the classifier', () {
      final lines = priced2([
        [('POUDRE', 0), ('1.64', 38)],
        [('YAOURT', 0), ('1.30', 38)],
        [('ALINENTAIRE', 0), ('2.94', 38)],
        [('SAVON', 0), ('2.07', 38)],
        [('TOTAL', 0), ('A', 6), ('PAYER', 8), ('5.01', 38)],
      ]);
      final probas = [
        itemP,
        itemP,
        [0.995, 0.0, 0.0, 0.0, 0.005],
        itemP,
        totalP,
      ];
      final hypothesis = decodeConstrained(lines, probas)!;
      expect(hypothesis.labels, [
        labelItem,
        labelItem,
        labelIgnore,
        labelItem,
        labelTotal,
      ]);
    });

    test('sections sum verifies when the final total is unreadable', () {
      final lines = priced2([
        [('PURE', 0), ('7,05', 38)],
        [('KIT', 0), ('5,50', 38)],
        [('Total', 0), ('Soins', 6), ('12,55', 38)],
        [('CRF', 0), ('KIT', 4), ('9.90', 38)],
        [('Total', 0), ('Non', 6), ('Alimentaire', 10), ('9.90', 38)],
      ]);
      final probas = [
        itemP,
        itemP,
        ignoreP,
        itemP,
        [0.0, 0.0, 0.78, 0.0, 0.22],
      ];
      final hypothesis = decodeConstrained(lines, probas)!;
      expect(hypothesis.referenceCents, 2245);
      expect(hypothesis.labels, [
        labelItem,
        labelItem,
        labelIgnore,
        labelItem,
        labelIgnore,
      ]);
    });
  });

  group('payment fallback', () {
    final rows = [
      [('PAIN', 0), ('2,00', 38)],
      [('LAIT', 0), ('3,00', 38)],
      [('TOTAL', 0), ('9,90', 38)],
      [('CB', 0), ('5,00', 38)],
    ];

    test('payment verifies when argmax items land on it', () {
      final hypothesis = decodeConstrained(priced2(rows), [
        itemP,
        itemP,
        totalP,
        paymentP,
      ])!;
      expect(hypothesis.referenceRole, labelPayment);
      expect(hypothesis.labels.sublist(0, 2), [labelItem, labelItem]);
    });

    test('payment never flips a line', () {
      final lines = priced2([
        rows[0],
        rows[1],
        rows[2],
        [('CB', 0), ('2,00', 38)],
      ]);
      final probas = [
        itemP,
        [0.55, 0.0, 0.0, 0.0, 0.45],
        totalP,
        paymentP,
      ];
      expect(decodeConstrained(lines, probas), isNull);
    });
  });

  group('single item', () {
    final parking = [
      [('PRIX', 0), ('HT', 5), ('12,25', 36)],
      [('TVA', 0), ('20,00%', 4), ('2,45', 36)],
      [('PRIX', 0), ('TTC', 5), ('14,70', 36)],
    ];
    final probas = [
      [0.9, 0.0, 0.0, 0.0, 0.1],
      ignoreP,
      [0.92, 0.0, 0.08, 0.0, 0.0],
    ];

    test('tax proof with nothing else priced is a single item', () {
      final hypothesis = decodeConstrained(priced2(parking), probas)!;
      expect(hypothesis.singleItem, isTrue);
      expect(hypothesis.referenceCents, 1470);
      expect(hypothesis.labels, [labelIgnore, labelIgnore, labelTotal]);
    });

    test('refused when printed count expects several items', () {
      expect(
        decodeConstrained(priced2(parking), probas, printedCount: 2),
        isNull,
      );
    });

    test('refused without an arithmetic source', () {
      final lines = priced2([
        [('TOTAL', 0), ('A', 6), ('PAYER', 8), ('4.70', 38)],
        [('ESPECES', 0), ('4.70', 38)],
      ]);
      expect(decodeConstrained(lines, [totalP, paymentP]), isNull);
    });

    test('refused when an item candidate exists', () {
      final lines = priced2([
        [('CAFE', 0), ('1,00', 38)],
        ...parking,
      ]);
      expect(decodeConstrained(lines, [itemP, ...probas]), isNull);
    });
  });

  group('amount alternatives', () {
    test('alternative amount is used when the primary cannot sum', () {
      final lines = [
        options(200, 0.9, 0.05, 0.05),
        LineOptions(
          cents: 5275,
          logProbs: {labelItem: math.log(0.9), labelIgnore: math.log(0.1)},
          alternativeCents: 275,
        ),
      ];
      final assignment = bestAssignmentDetail(lines, 475)!;
      expect(assignment.labels, [labelItem, labelItem]);
      expect(assignment.cents, [200, 275]);
    });

    test('primary amount is preferred when both sum', () {
      final lines = [
        LineOptions(
          cents: 200,
          logProbs: {labelItem: math.log(0.9), labelIgnore: math.log(0.1)},
          alternativeCents: 200,
        ),
      ];
      expect(bestAssignmentDetail(lines, 200)!.cents, [200]);
    });

    test('decode with alternatives rewrites the chosen amount', () {
      final lines = priced2([
        [('TORT', 0), ('RICOTTA', 5), ('S2.75e', 36)],
        [('PAIN', 0), ('2,00', 38)],
        [('TOTAL', 0), ('4,75', 38)],
      ]);
      final hypothesis = decodeConstrained(
        lines,
        [itemP, itemP, totalP],
        alternatives: {0: 275},
      )!;
      expect(hypothesis.labels, [labelItem, labelItem, labelTotal]);
      expect(hypothesis.cents[0], 275);
    });

    test('forced ignore lines keep their price', () {
      final lines = priced2([
        [('PAIN', 0), ('2,00', 38)],
        [('TOTAL', 0), ('2,00', 38)],
      ]);
      final rewritten = withChosenAmounts(
        lines,
        [labelItem, labelTotal],
        [200, 0],
      );
      expect([for (final p in rewritten) p.price], [2.0, 2.0]);
    });
  });

  group('receiptFromLabels', () {
    final merged = receiptLines([
      [('STORE', 10)],
      [('POMME', 0), ('2.00', 38)],
      [('REMISE', 0), ('-0.50', 38)],
      [('TOTAL', 0), ('1.50', 38)],
    ]);
    final lines = pricedLines(merged);

    test('discount attaches to previous item', () {
      final receipt = receiptFromLabels(merged, lines, [
        labelItem,
        labelDiscount,
        labelTotal,
      ])!;
      expect(
        [for (final i in receipt.items) (i.amount, i.discount)],
        [(2.0, 0.5)],
      );
      expect(receipt.total, 1.5);
      expect(receipt.checksumOk, isTrue);
    });

    test('negative price labelled item becomes a discount', () {
      final receipt = receiptFromLabels(merged, lines, [
        labelItem,
        labelItem,
        labelTotal,
      ])!;
      expect(
        [for (final i in receipt.items) (i.amount, i.discount)],
        [(2.0, 0.5)],
      );
    });

    test('no items returns null', () {
      expect(
        receiptFromLabels(merged, lines, [
          labelIgnore,
          labelIgnore,
          labelTotal,
        ]),
        isNull,
      );
    });

    test('virtual reference fills a missing total', () {
      final receipt = receiptFromLabels(merged, lines, [
        labelItem,
        labelDiscount,
        labelIgnore,
      ], referenceTotal: 1.5)!;
      expect(receipt.total, 1.5);
      expect(receipt.checksumOk, isTrue);
    });

    test('labelled total wins over the reference', () {
      final receipt = receiptFromLabels(merged, lines, [
        labelItem,
        labelDiscount,
        labelTotal,
      ], referenceTotal: 9.99)!;
      expect(receipt.total, 1.5);
    });

    test('single item receipt is named after the store', () {
      final receipt = singleItemReceipt(merged, 14.7);
      expect(
        [for (final i in receipt.items) (i.name, i.amount, i.discount)],
        [('STORE', 14.7, 0.0)],
      );
      expect(receipt.total, 14.7);
      expect(receipt.checksumOk, isTrue);
    });

    test('constrained labels drop forced ignore and ineligible totals', () {
      const structure = Constraints(
        forcedIgnore: {1},
        referenceRanks: {3},
        evidences: [],
      );
      expect(
        constrainedLabels([
          labelItem,
          labelItem,
          labelTotal,
          labelTotal,
        ], structure),
        [labelItem, labelIgnore, labelIgnore, labelTotal],
      );
    });
  });
}
