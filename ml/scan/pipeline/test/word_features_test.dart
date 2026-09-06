library;

import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

const double charWidth = 10.0;
const double lineHeight = 20.0;

Word word(String text, double column, int row) {
  final left = column * charWidth;
  final top = row * (lineHeight + 5);
  return Word(
    text: text,
    left: left,
    top: top,
    right: left + text.length * charWidth,
    bottom: top + lineHeight,
    confidence: 1.0,
  );
}

PhysicalLine line(int row, List<(String, double)> tokens) => PhysicalLine(
  words: [for (final token in tokens) word(token.$1, token.$2, row)],
);

int columnOf(String name) => wordFeatureNames.indexOf(name);

final ticket = [
  line(0, [('6015', 0), ('SANDWICH POULET', 8), ('2,95', 40)]),
  line(1, [('6011', 0), ('SALADE CESAR', 8), ('1,29', 40)]),
  line(2, [('6012', 0), ('EAU MINERALE', 8), ('0,71', 40)]),
];

void main() {
  group('bandes', () {
    test('une colonne de codes est vue comme numérique', () {
      expect(featurizeWords(ticket)[0][0][columnOf('band_digit_ratio')], 1.0);
    });

    test('une colonne de libellés est vue comme alphabétique', () {
      expect(
        featurizeWords(ticket)[0][1][columnOf('band_alpha_ratio')],
        greaterThan(0.8),
      );
    });

    test('une colonne de prix est vue comme telle', () {
      expect(featurizeWords(ticket)[0][2][columnOf('band_price_ratio')], 1.0);
    });

    test('un mot seul dans sa bande n\'a pas de colonne', () {
      final rows = featurizeWords([
        ...ticket,
        line(3, [('MERCI DE VOTRE VISITE', 60)]),
      ]);
      expect(rows[3][0][columnOf('band_fill')], 0.0);
    });
  });

  group('géométrie', () {
    test('le premier et le dernier mot sont marqués', () {
      final rows = featurizeWords(ticket);
      expect(rows[0][0][columnOf('is_first')], 1.0);
      expect(rows[0][2][columnOf('is_last')], 1.0);
    });

    test('l\'écart avant le premier mot est absent', () {
      expect(
        featurizeWords(ticket)[0][0][columnOf('gap_before')],
        wordNeighbourAbsent,
      );
    });

    test('l\'écart sépare deux colonnes', () {
      expect(
        featurizeWords(ticket)[0][1][columnOf('gap_after')],
        greaterThan(0.0),
      );
    });
  });

  group('prix', () {
    test('le mot qui porte le prix est désigné', () {
      final rows = featurizeWords(ticket);
      expect(rows[0][2][columnOf('is_price_word')], 1.0);
      expect(rows[0][1][columnOf('is_price_word')], 0.0);
    });

    test('un prix fragmenté reste reconnu', () {
      final rows = featurizeWords([
        line(0, [('PAIN', 0), ('2,', 40), ('95', 42.5)]),
      ]);
      expect(rows[0][0][columnOf('is_price_word')], 0.0);
      expect(rows[0][1][columnOf('is_price_word')], 1.0);
      expect(rows[0][2][columnOf('is_price_word')], 1.0);
    });

    test('une ligne sans prix n\'a pas de distance au prix', () {
      final rows = featurizeWords([
        line(0, [('BOULANGERIE', 0), ('DUPONT', 12)]),
      ]);
      expect(rows[0][0][columnOf('dist_to_price')], wordNeighbourAbsent);
    });
  });

  group('contrat', () {
    test('chaque mot donne un vecteur de la bonne largeur', () {
      final rows = featurizeWords(ticket);
      expect([for (final row in rows) row.length], [3, 3, 3]);
      for (final row in rows) {
        for (final vector in row) {
          expect(vector.length, wordFeatureNames.length);
        }
      }
    });

    test('un ticket vide ne donne rien', () {
      expect(featurizeWords(const []), isEmpty);
    });
  });
}
