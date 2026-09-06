import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/scan/receipt_item_name.dart';

void main() {
  group('receiptItemDisplayName', () {
    test('un libellé tout en capitales passe en casse de phrase', () {
      expect(receiptItemDisplayName('PAIN COMPLET'), 'Pain complet');
    });

    test('les jetons qui portent un chiffre gardent leur casse', () {
      expect(receiptItemDisplayName('LAIT ECREME 6X1L'), 'Lait ecreme 6X1L');
    });

    test('un libellé déjà en casse mixte est laissé tel quel', () {
      expect(
        receiptItemDisplayName('Café moulu Arabica'),
        'Café moulu Arabica',
      );
    });

    test('les marqueurs de ticket en tête sont retirés', () {
      expect(receiptItemDisplayName('* BANANES BIO'), 'Bananes bio');
      expect(receiptItemDisplayName('- ESSUIE TOUT'), 'Essuie tout');
    });

    test('la première lettre est capitalisée même après un chiffre', () {
      expect(receiptItemDisplayName('2X YAOURT NATURE'), '2X Yaourt nature');
    });

    test('les espaces multiples sont réduits', () {
      expect(receiptItemDisplayName('  PAIN   COMPLET '), 'Pain complet');
    });

    test('les accents ne sont jamais inventés', () {
      expect(receiptItemDisplayName('CAFE MOULU'), 'Cafe moulu');
    });

    test('un libellé vide reste vide', () {
      expect(receiptItemDisplayName('   '), '');
      expect(receiptItemDisplayName('***'), '');
    });
  });
}
