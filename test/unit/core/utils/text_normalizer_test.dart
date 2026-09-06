import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/utils/text_normalizer.dart';

void main() {
  group('TextNormalizer.normalize', () {
    test('lowercases and trims', () {
      expect(TextNormalizer.normalize('  MacDo  '), 'macdo');
    });

    test('strips diacritics', () {
      expect(TextNormalizer.normalize('Café Crème'), 'cafe creme');
      expect(TextNormalizer.normalize('PÉAGE'), 'peage');
      expect(
        TextNormalizer.normalize('Garçon naïf où ça'),
        'garcon naif ou ca',
      );
    });

    test('collapses whitespace runs', () {
      expect(
        TextNormalizer.normalize('Super\t  Marché\nBio'),
        'super marche bio',
      );
    });

    test('returns empty for blank input', () {
      expect(TextNormalizer.normalize('   '), '');
      expect(TextNormalizer.normalize(''), '');
    });

    test('is idempotent', () {
      const raw = 'Épicerie   FINE';
      expect(
        TextNormalizer.normalize(TextNormalizer.normalize(raw)),
        TextNormalizer.normalize(raw),
      );
    });
  });
}
