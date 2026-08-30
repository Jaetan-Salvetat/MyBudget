library;

import 'dart:math' as math;

import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

const double height = 30.0;
const double charWidth = 14.0;

Word wordAt(String text, int column, double centerY) {
  final left = column * charWidth;
  return Word(
    text: text,
    left: left,
    top: centerY - height / 2,
    right: left + text.length * charWidth,
    bottom: centerY + height / 2,
    confidence: 0.9,
  );
}

List<Word> printedLine(
  List<(String, int)> tokens,
  double baseline,
  double slope,
) => [
  for (final (text, column) in tokens)
    wordAt(text, column, baseline + slope * column * charWidth),
];

List<List<String>> textsOf(List<List<Word>> groups) => [
  for (final group in groups)
    [
      for (final word
          in (group.toList()..sort((a, b) => a.left.compareTo(b.left))))
        word.text,
    ],
];

List<Word> merged([double slope = 0.0]) => [
  ...printedLine([('PREM', 0), ('AGGLO', 6), ('16,99', 38)], 100.0, slope),
  ...printedLine([('Reduction', 0), ('-4,49', 38)], 140.0, slope),
];

void main() {
  group('une ligne imprimée seule ne se sépare jamais', () {
    test('deux mots restent ensemble quel que soit leur décalage', () {
      expect(
        splitBaselines([wordAt('PAIN', 0, 0.0), wordAt('2,50', 38, 200.0)]),
        hasLength(1),
      );
    });

    test('une ligne horizontale est un seul groupe', () {
      final line = printedLine(
        [('PAIN', 0), ('BIO', 6), ('2,50', 38)],
        100.0,
        0.0,
      );
      expect(splitBaselines(line), hasLength(1));
    });

    test('une ligne très inclinée reste un seul groupe', () {
      final slope = math.tan(6 * math.pi / 180);
      final line = printedLine(
        [('PAIN', 0), ('BIO', 6), ('2,50', 38)],
        100.0,
        slope,
      );
      expect(splitBaselines(line), hasLength(1));
    });
  });

  group('deux lignes imprimées sont séparées', () {
    test('une paire fusionnée se recoupe en deux', () {
      expect(textsOf(splitBaselines(merged())), [
        ['PREM', 'AGGLO', '16,99'],
        ['Reduction', '-4,49'],
      ]);
    });

    test('la séparation survit à une inclinaison partagée', () {
      final slope = math.tan(4 * math.pi / 180);
      expect(textsOf(splitBaselines(merged(slope))), [
        ['PREM', 'AGGLO', '16,99'],
        ['Reduction', '-4,49'],
      ]);
    });

    test('aucun mot n\'est perdu ni dupliqué', () {
      final words = merged();
      final regrouped = [
        for (final group in splitBaselines(words))
          for (final word in group) word.text,
      ]..sort();
      expect(regrouped, [for (final word in words) word.text]..sort());
    });

    test('chaque ligne garde son propre montant', () {
      final amounts = [
        for (final group in splitBaselines(merged()))
          [
            for (final word in group)
              if (word.text.contains(',')) word.text,
          ],
      ];
      expect(amounts, [
        ['16,99'],
        ['-4,49'],
      ]);
    });
  });

  group('le regroupement utilise la séparation', () {
    test('un ticket courbé rend une ligne par ligne imprimée', () {
      final words = [
        ...printedLine([('PREM', 0), ('AGGLO', 6), ('16,99', 38)], 100.0, 0.03),
        ...printedLine([('Reduction', 0), ('-4,49', 38)], 125.0, 0.03),
      ];
      expect(clusterLines(words, split: false), hasLength(1));
      expect(
        [for (final line in clusterLines(words)) line.text],
        ['PREM AGGLO 16,99', 'Reduction -4,49'],
      );
    });

    test('deux lignes bien séparées ne bougent pas', () {
      final words = [
        ...printedLine([('PAIN', 0), ('2,50', 38)], 100.0, 0.0),
        ...printedLine([('LAIT', 0), ('3,00', 38)], 300.0, 0.0),
      ];
      expect(
        [for (final line in clusterLines(words)) line.text],
        ['PAIN 2,50', 'LAIT 3,00'],
      );
    });
  });
}
