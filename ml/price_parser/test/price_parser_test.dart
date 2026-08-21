import 'package:price_parser/price_parser.dart';
import 'package:test/test.dart';

PriceResult _r(String input, double price, String remaining) =>
    PriceResult(fullText: input, price: price, remaining: remaining);

void main() {
  group('parsePrice', () {
    group('montant simple en fin de phrase', () {
      final cases = {
        'macdo 15': _r('macdo 15', 15.0, 'macdo'),
        'uber 23': _r('uber 23', 23.0, 'uber'),
        'café 4': _r('café 4', 4.0, 'café'),
        'boulangerie 3': _r('boulangerie 3', 3.0, 'boulangerie'),
        'resto 45': _r('resto 45', 45.0, 'resto'),
        'coiffeur 35': _r('coiffeur 35', 35.0, 'coiffeur'),
        'cinema 12': _r('cinema 12', 12.0, 'cinema'),
        'parking 6': _r('parking 6', 6.0, 'parking'),
        'essence 70': _r('essence 70', 70.0, 'essence'),
        'supermarché 87': _r('supermarché 87', 87.0, 'supermarché'),
      };
      for (final entry in cases.entries) {
        test('"${entry.key}" → ${entry.value}', () {
          expect(parsePrice(entry.key), entry.value);
        });
      }
    });

    group('montant simple en début de phrase', () {
      final cases = {
        '15 macdo': _r('15 macdo', 15.0, 'macdo'),
        '23 uber': _r('23 uber', 23.0, 'uber'),
        '4 café': _r('4 café', 4.0, 'café'),
        '250 cadeaux maman': _r('250 cadeaux maman', 250.0, 'cadeaux maman'),
        '70 plein essence': _r('70 plein essence', 70.0, 'plein essence'),
      };
      for (final entry in cases.entries) {
        test('"${entry.key}" → ${entry.value}', () {
          expect(parsePrice(entry.key), entry.value);
        });
      }
    });

    group('montant avec décimales (point)', () {
      final cases = {
        'macdo 15.50': _r('macdo 15.50', 15.50, 'macdo'),
        'café 3.80': _r('café 3.80', 3.80, 'café'),
        'uber 12.99': _r('uber 12.99', 12.99, 'uber'),
        'abonnement 9.99': _r('abonnement 9.99', 9.99, 'abonnement'),
        'sandwich 4.50': _r('sandwich 4.50', 4.50, 'sandwich'),
      };
      for (final entry in cases.entries) {
        test('"${entry.key}" → ${entry.value}', () {
          expect(parsePrice(entry.key), entry.value);
        });
      }
    });

    group('montant avec décimales (virgule)', () {
      final cases = {
        'macdo 15,50': _r('macdo 15,50', 15.50, 'macdo'),
        'café 3,80': _r('café 3,80', 3.80, 'café'),
        'uber 12,99': _r('uber 12,99', 12.99, 'uber'),
        'boulangerie 1,20': _r('boulangerie 1,20', 1.20, 'boulangerie'),
        'pain 0,90': _r('pain 0,90', 0.90, 'pain'),
      };
      for (final entry in cases.entries) {
        test('"${entry.key}" → ${entry.value}', () {
          expect(parsePrice(entry.key), entry.value);
        });
      }
    });

    group('montant avec symbole monétaire', () {
      final cases = {
        'macdo 15€': _r('macdo 15€', 15.0, 'macdo'),
        'uber 23€': _r('uber 23€', 23.0, 'uber'),
        'café 3.50€': _r('café 3.50€', 3.50, 'café'),
        'resto 45 €': _r('resto 45 €', 45.0, 'resto'),
        r'groceries $50': _r(r'groceries $50', 50.0, 'groceries'),
        r'taxi $12.30': _r(r'taxi $12.30', 12.30, 'taxi'),
        r'coffee £3.50': _r(r'coffee £3.50', 3.50, 'coffee'),
        'achat 19,99€': _r('achat 19,99€', 19.99, 'achat'),
        'achat 19,99 €': _r('achat 19,99 €', 19.99, 'achat'),
      };
      for (final entry in cases.entries) {
        test('"${entry.key}" → ${entry.value}', () {
          expect(parsePrice(entry.key), entry.value);
        });
      }
    });

    group('expressions familières avec montant', () {
      final cases = {
        "Romane m'a filé 15 balles":
            _r("Romane m'a filé 15 balles", 15.0, "Romane m'a filé"),
        "j'ai payé 30 balles pour le resto":
            _r("j'ai payé 30 balles pour le resto", 30.0, "j'ai payé pour le resto"),
        "ça m'a coûté 25 euros":
            _r("ça m'a coûté 25 euros", 25.0, "ça m'a coûté"),
        "j'ai claqué 200 balles en fringues":
            _r("j'ai claqué 200 balles en fringues", 200.0, "j'ai claqué en fringues"),
        'il me doit 50 euros':
            _r('il me doit 50 euros', 50.0, 'il me doit'),
        "j'ai lâché 18 balles":
            _r("j'ai lâché 18 balles", 18.0, "j'ai lâché"),
        'payé 60 pour la coupe':
            _r('payé 60 pour la coupe', 60.0, 'payé pour la coupe'),
        'dépensé 120 en courses':
            _r('dépensé 120 en courses', 120.0, 'dépensé en courses'),
      };
      for (final entry in cases.entries) {
        test('"${entry.key}" → ${entry.value}', () {
          expect(parsePrice(entry.key), entry.value);
        });
      }
    });

    group('phrases en anglais', () {
      final cases = {
        'lunch 12': _r('lunch 12', 12.0, 'lunch'),
        'groceries 85': _r('groceries 85', 85.0, 'groceries'),
        'paid 40 for dinner':
            _r('paid 40 for dinner', 40.0, 'paid for dinner'),
        'spent 25 on coffee':
            _r('spent 25 on coffee', 25.0, 'spent on coffee'),
        'gas 55': _r('gas 55', 55.0, 'gas'),
        'rent 1200': _r('rent 1200', 1200.0, 'rent'),
        'netflix 15.99': _r('netflix 15.99', 15.99, 'netflix'),
        'phone bill 45': _r('phone bill 45', 45.0, 'phone bill'),
      };
      for (final entry in cases.entries) {
        test('"${entry.key}" → ${entry.value}', () {
          expect(parsePrice(entry.key), entry.value);
        });
      }
    });

    group('phrases en espagnol', () {
      final cases = {
        'almuerzo 12': _r('almuerzo 12', 12.0, 'almuerzo'),
        'gasolina 40': _r('gasolina 40', 40.0, 'gasolina'),
        'pagué 30 por la cena':
            _r('pagué 30 por la cena', 30.0, 'pagué por la cena'),
        'supermercado 65': _r('supermercado 65', 65.0, 'supermercado'),
        'taxi 8,50': _r('taxi 8,50', 8.50, 'taxi'),
      };
      for (final entry in cases.entries) {
        test('"${entry.key}" → ${entry.value}', () {
          expect(parsePrice(entry.key), entry.value);
        });
      }
    });

    group('phrases en allemand', () {
      final cases = {
        'Mittagessen 12': _r('Mittagessen 12', 12.0, 'Mittagessen'),
        'Benzin 55': _r('Benzin 55', 55.0, 'Benzin'),
        'Miete 800': _r('Miete 800', 800.0, 'Miete'),
        'Kaffee 3,50': _r('Kaffee 3,50', 3.50, 'Kaffee'),
        'Supermarkt 42': _r('Supermarkt 42', 42.0, 'Supermarkt'),
      };
      for (final entry in cases.entries) {
        test('"${entry.key}" → ${entry.value}', () {
          expect(parsePrice(entry.key), entry.value);
        });
      }
    });

    group('grands montants', () {
      final cases = {
        'loyer 1200': _r('loyer 1200', 1200.0, 'loyer'),
        'loyer 1 200': _r('loyer 1 200', 1200.0, 'loyer'),
        'rent 1,200': _r('rent 1,200', 1200.0, 'rent'),
        'voiture 15000': _r('voiture 15000', 15000.0, 'voiture'),
        'salaire 2500': _r('salaire 2500', 2500.0, 'salaire'),
        'prime 3 000': _r('prime 3 000', 3000.0, 'prime'),
      };
      for (final entry in cases.entries) {
        test('"${entry.key}" → ${entry.value}', () {
          expect(parsePrice(entry.key), entry.value);
        });
      }
    });

    group('phrases avec contexte supplémentaire', () {
      final cases = {
        'cadeaux maman 250':
            _r('cadeaux maman 250', 250.0, 'cadeaux maman'),
        'anniversaire paul 80':
            _r('anniversaire paul 80', 80.0, 'anniversaire paul'),
        'remboursement julie 35':
            _r('remboursement julie 35', 35.0, 'remboursement julie'),
        'prêté à Marc 100':
            _r('prêté à Marc 100', 100.0, 'prêté à Marc'),
        'Romane me doit 40':
            _r('Romane me doit 40', 40.0, 'Romane me doit'),
        'reçu 500 de papa':
            _r('reçu 500 de papa', 500.0, 'reçu de papa'),
        'virement maman 300':
            _r('virement maman 300', 300.0, 'virement maman'),
      };
      for (final entry in cases.entries) {
        test('"${entry.key}" → ${entry.value}', () {
          expect(parsePrice(entry.key), entry.value);
        });
      }
    });

    group('phrases ambiguës avec plusieurs nombres', () {
      final cases = {
        '2 cafés 7': _r('2 cafés 7', 7.0, '2 cafés'),
        '3 bières 18': _r('3 bières 18', 18.0, '3 bières'),
        '2 places ciné 24': _r('2 places ciné 24', 24.0, '2 places ciné'),
        '4 tickets metro 8': _r('4 tickets metro 8', 8.0, '4 tickets metro'),
        '2 pizzas 25,90': _r('2 pizzas 25,90', 25.90, '2 pizzas'),
        '3 croissants 3,60': _r('3 croissants 3,60', 3.60, '3 croissants'),
      };
      for (final entry in cases.entries) {
        test('"${entry.key}" → ${entry.value}', () {
          expect(parsePrice(entry.key), entry.value);
        });
      }
    });

    group('montant nul ou absent', () {
      test('"juste un mot" → null', () {
        expect(parsePrice('juste un mot'), isNull);
      });
      test('"hello" → null', () {
        expect(parsePrice('hello'), isNull);
      });
      test('"" → null', () {
        expect(parsePrice(''), isNull);
      });
    });

    group('formats avec séparateur de milliers ambigu', () {
      final cases = {
        'réparation 1 500,00':
            _r('réparation 1 500,00', 1500.0, 'réparation'),
        'salary 2,500.00': _r('salary 2,500.00', 2500.0, 'salary'),
        'bonus 10 000': _r('bonus 10 000', 10000.0, 'bonus'),
      };
      for (final entry in cases.entries) {
        test('"${entry.key}" → ${entry.value}', () {
          expect(parsePrice(entry.key), entry.value);
        });
      }
    });

    group('syntaxes relâchées / abréviations', () {
      final cases = {
        'mcdo 8': _r('mcdo 8', 8.0, 'mcdo'),
        'McDo 14,50': _r('McDo 14,50', 14.50, 'McDo'),
        'UberEats 22.90': _r('UberEats 22.90', 22.90, 'UberEats'),
        'sncf 89': _r('sncf 89', 89.0, 'sncf'),
        'SNCF billet 35': _r('SNCF billet 35', 35.0, 'SNCF billet'),
        'rer 2': _r('rer 2', 2.0, 'rer'),
        'clope 11,50': _r('clope 11,50', 11.50, 'clope'),
        'tacos 9': _r('tacos 9', 9.0, 'tacos'),
      };
      for (final entry in cases.entries) {
        test('"${entry.key}" → ${entry.value}', () {
          expect(parsePrice(entry.key), entry.value);
        });
      }
    });

    group('montant au milieu de la phrase', () {
      final cases = {
        "j'ai mis 50 sur mon compte":
            _r("j'ai mis 50 sur mon compte", 50.0, "j'ai mis sur mon compte"),
        "elle m'a rendu 20 hier":
            _r("elle m'a rendu 20 hier", 20.0, "elle m'a rendu hier"),
        "j'ai gagné 150 au poker":
            _r("j'ai gagné 150 au poker", 150.0, "j'ai gagné au poker"),
        'received 200 from client':
            _r('received 200 from client', 200.0, 'received from client'),
        'got 75 back from insurance':
            _r('got 75 back from insurance', 75.0, 'got back from insurance'),
      };
      for (final entry in cases.entries) {
        test('"${entry.key}" → ${entry.value}', () {
          expect(parsePrice(entry.key), entry.value);
        });
      }
    });
  });
}
