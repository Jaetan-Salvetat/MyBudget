import 'dart:math' as math;

import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

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

PricedLine priced(int index, double price, {String label = 'ART'}) {
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

void main() {
  group('bestAssignment', () {
    test('argmax when it already sums to target', () {
      final lines = [options(200, 0.9, 0.05, 0.05), options(300, 0.9, 0.05, 0.05)];
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
      final lines = [options(200, 0.9, 0.05, 0.05), options(300, 0.4, 0.05, 0.55)];
      expect(bestAssignment(lines, 500), [labelItem, labelItem]);
    });

    test('discount subtracts', () {
      final lines = [options(1000, 0.9, 0.05, 0.05), options(-250, 0.05, 0.9, 0.05)];
      expect(bestAssignment(lines, 750), [labelItem, labelDiscount]);
    });

    test('positive discount line subtracts too', () {
      final lines = [options(1000, 0.9, 0.05, 0.05), options(250, 0.3, 0.6, 0.1)];
      expect(bestAssignment(lines, 750), [labelItem, labelDiscount]);
    });

    test('no solution returns null', () {
      final lines = [options(200, 0.9, 0.05, 0.05), options(300, 0.9, 0.05, 0.05)];
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
      final lines = [options(200, 0.9, 0.05, 0.05), options(300, 0.001, 0.001, 0.998)];
      expect(bestAssignment(lines, 500, minProb: 0.01), isNull);
    });

    test('empty lines', () {
      expect(bestAssignment([], 0), isEmpty);
    });
  });

  group('structural constraints', () {
    List<List<double>> uniform(int count) =>
        List.generate(count, (_) => [0.8, 0.1, 0.05, 0.0, 0.05]);

    test('zero cent line is never an item', () {
      final lines = [priced(0, 0.0), priced(1, 2.0)];
      final opts = lineOptions(lines, uniform(2), 2);
      expect(opts[0].logProbs.keys, [labelIgnore]);
      expect(opts[1].logProbs.containsKey(labelItem), isTrue);
    });

    test('lines after reference are forced to ignore', () {
      final lines = [priced(0, 2.0), priced(1, 3.0), priced(2, 5.0), priced(3, 1.5)];
      final opts = lineOptions(lines, uniform(4), 2);
      expect(opts[0].logProbs.containsKey(labelItem), isTrue);
      expect(opts[2].logProbs.keys, [labelIgnore]);
    });

    test('negative price cannot be an item', () {
      final lines = [priced(0, 2.0), priced(1, -1.0), priced(2, 5.0)];
      final opts = lineOptions(lines, uniform(3), 2);
      expect(opts[1].logProbs.containsKey(labelItem), isFalse);
      expect(opts[1].logProbs.containsKey(labelDiscount), isTrue);
    });
  });

  group('payment fallback', () {
    List<List<double>> probas() => [
          [0.99, 0.0, 0.0, 0.0, 0.01],
          [0.99, 0.0, 0.0, 0.0, 0.01],
          [0.0, 0.0, 0.99, 0.0, 0.01],
          [0.0, 0.0, 0.0, 0.99, 0.01],
        ];

    test('payment rescues when argmax items match it', () {
      final lines = [priced(0, 2.0), priced(1, 3.0), priced(2, 9.9), priced(3, 5.0)];
      final hypothesis = decodeConstrained(lines, probas());
      expect(hypothesis, isNotNull);
      expect(hypothesis!.referenceRole, labelPayment);
      expect(hypothesis.labels, [labelItem, labelItem, labelIgnore, labelPayment]);
    });

    test('payment never rescues with a flip', () {
      final lines = [priced(0, 2.0), priced(1, 3.0), priced(2, 9.9), priced(3, 2.0)];
      final rows = probas();
      rows[1] = [0.6, 0.0, 0.0, 0.0, 0.4];
      expect(decodeConstrained(lines, rows), isNull);
    });
  });

  group('receiptFromLabels', () {
    final merged = [
      priced(0, 2.0, label: 'POMME').line,
      priced(1, -0.5, label: 'REMISE').line,
      priced(2, 1.5, label: 'TOTAL').line,
    ];
    final lines = [priced(0, 2.0, label: 'POMME'), priced(1, -0.5, label: 'REMISE'), priced(2, 1.5, label: 'TOTAL')];

    test('discount attaches to previous item', () {
      final receipt = receiptFromLabels(merged, lines, [labelItem, labelDiscount, labelTotal])!;
      expect([for (final i in receipt.items) (i.amount, i.discount)], [(2.0, 0.5)]);
      expect(receipt.total, 1.5);
      expect(receipt.checksumOk, isTrue);
    });

    test('negative price labelled item becomes a discount', () {
      final receipt = receiptFromLabels(merged, lines, [labelItem, labelItem, labelTotal])!;
      expect([for (final i in receipt.items) (i.amount, i.discount)], [(2.0, 0.5)]);
    });

    test('no items returns null', () {
      expect(receiptFromLabels(merged, lines, [labelIgnore, labelIgnore, labelTotal]), isNull);
    });
  });
}
