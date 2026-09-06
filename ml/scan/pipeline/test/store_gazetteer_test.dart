library;

import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

final Gazetteer gazetteer = Gazetteer({
  'CARREFOUR': 'Carrefour',
  'CARREFOUR MARKET': 'Carrefour Market',
  'MCDONALD S': "McDonald's",
  'U': 'U',
  'INTERMARCHE': 'Intermarché',
});

void main() {
  group('normalisation', () {
    test('majuscules, accents et ponctuation ne comptent pas', () {
      expect(normalizeStore('Intermarché !'), 'INTERMARCHE');
      expect(normalizeStore("McDonald's"), 'MCDONALD S');
    });

    test('les espaces multiples se réduisent', () {
      expect(normalizeStore('  CARREFOUR   CITY '), 'CARREFOUR CITY');
    });
  });

  group('reconnaissance', () {
    test('la ligne entière', () {
      expect(gazetteer.match('Intermarché'), 'Intermarché');
    });

    test('le nom le plus long gagne', () {
      expect(gazetteer.match('CARREFOUR MARKET GRENOBLE'), 'Carrefour Market');
    });

    test('un nom contenu dans la ligne', () {
      expect(gazetteer.match('SAS CARREFOUR 38000'), 'Carrefour');
    });

    test('une entrée courte doit être la ligne entière', () {
      expect(gazetteer.match('U'), 'U');
      expect(gazetteer.match('RUE DU MARCHE'), isNull);
    });

    test('un logo abîmé par l OCR reste reconnu', () {
      expect(gazetteer.match('CARREFOJR'), 'Carrefour');
    });

    test('un logo trop abîmé ne l est pas', () {
      expect(gazetteer.match('XXXXXXXXX'), isNull);
    });

    test('une ligne vide ne reconnaît rien', () {
      expect(gazetteer.match(''), isNull);
      expect(gazetteer.match('   '), isNull);
    });

    test('une enseigne inconnue ne rend rien', () {
      expect(gazetteer.match('BOULANGERIE DUPONT'), isNull);
    });
  });
}
