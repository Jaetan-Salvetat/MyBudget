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
  });
}
