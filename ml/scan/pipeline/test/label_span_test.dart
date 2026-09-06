library;

import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

void main() {
  test('l\'intervalle retenu est celui des mots probables', () {
    expect(
      bestSpan(['583877', 'DIAMOND', 'TAPIS', '29.95'], [0.1, 0.9, 0.9, 0.02]),
      const LabelSpan(1, 3),
    );
  });

  test('l\'intervalle reste contigu', () {
    expect(
      bestSpan(['PAIN', '6015', 'COMPLET'], [0.9, 0.05, 0.6]),
      const LabelSpan(0, 1),
    );
  });

  test('le pont se paie quand il vaut le coup', () {
    expect(
      bestSpan(['PAIN', '6015', 'COMPLET'], [0.99, 0.45, 0.99]),
      const LabelSpan(0, 3),
    );
  });

  test('un libellé sans lettre n\'en est pas un', () {
    expect(bestSpan(['0.335', '4.35'], [0.9, 0.9]), isNull);
  });

  test('l\'intervalle le plus probable porte des lettres', () {
    expect(bestSpan(['2', 'AVOCAT'], [0.9, 0.55]), const LabelSpan(0, 2));
  });

  test('une ligne vide ne donne pas d\'intervalle', () {
    expect(bestSpan(const [], const []), isNull);
  });

  test('le texte est celui des mots de l\'intervalle', () {
    expect(
      spanText(['583877', 'DIAMOND', 'TAPIS'], const LabelSpan(1, 3)),
      'DIAMOND TAPIS',
    );
  });
}
