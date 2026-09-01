import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/quick_add/price_parser_service.dart';

void main() {
  group('PriceParserService', () {
    test('parses integer amount', () {
      final result = PriceParserService.parse('mc do 12');

      expect(result, isNotNull);
      expect(result!.price, 12.0);
      expect(result.remaining, 'mc do');
    });

    test('parses french decimal amount', () {
      final result = PriceParserService.parse('café 3,50');

      expect(result!.price, 3.50);
      expect(result.remaining, 'café');
    });

    test('parses english decimal amount', () {
      final result = PriceParserService.parse('netflix 13.99');

      expect(result!.price, 13.99);
      expect(result.remaining, 'netflix');
    });

    test('strips currency symbols from remaining text', () {
      final result = PriceParserService.parse('courses 45€');

      expect(result!.price, 45.0);
      expect(result.remaining, 'courses');
    });

    test('strips money words from remaining text', () {
      final result = PriceParserService.parse("j'ai filé 20 balles");

      expect(result!.price, 20.0);
      expect(result.remaining, "j'ai filé");
    });

    test('parses french thousands separator', () {
      final result = PriceParserService.parse('loyer 1 200');

      expect(result!.price, 1200.0);
      expect(result.remaining, 'loyer');
    });

    test('parses english thousands separator with decimals', () {
      final result = PriceParserService.parse('salary 2,500.50');

      expect(result!.price, 2500.50);
      expect(result.remaining, 'salary');
    });

    test('picks the last amount when several are present', () {
      final result = PriceParserService.parse('2 pizzas 24');

      expect(result!.price, 24.0);
    });

    test('returns null when no amount is present', () {
      expect(PriceParserService.parse('courses carrefour'), isNull);
    });

    test('returns null for empty input', () {
      expect(PriceParserService.parse('   '), isNull);
    });

    test('collapses extra whitespace in remaining text', () {
      final result = PriceParserService.parse('resto  midi 25 euros');

      expect(result!.remaining, 'resto midi');
    });

    // Un chiffre collé à des lettres appartient au nom, jamais au montant :
    // « plein de SP98 » arrivait au modèle comme « plein de SP », et il n'a
    // plus de quoi reconnaître du carburant.
    test('ignores a number glued to letters', () {
      expect(PriceParserService.parse('plein de SP98'), isNull);
      expect(PriceParserService.parse('A10 péage'), isNull);
      expect(PriceParserService.parse('Galaxy S24'), isNull);
    });

    test('still reads an amount glued to a currency symbol', () {
      final result = PriceParserService.parse('courses 45€');

      expect(result!.price, 45.0);
    });

    test('reads the amount when a glued number precedes it', () {
      final result = PriceParserService.parse('SP98 72,40');

      expect(result!.price, 72.40);
      expect(result.remaining, 'SP98');
    });

    // Une quantité porte son unité ; un montant n'en porte pas.
    test('ignores a number carrying a unit', () {
      expect(PriceParserService.parse('forfait 100 Go'), isNull);
      expect(PriceParserService.parse('2 kg de pommes'), isNull);
      expect(PriceParserService.parse('abonnement 12 mois'), isNull);
    });

    test('reads the amount when a quantity precedes it', () {
      final result = PriceParserService.parse('50 cl de bière 6,80');

      expect(result!.price, 6.80);
      expect(result.remaining, '50 cl de bière');
    });
  });
}
