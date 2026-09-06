import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';

const String groupSeparator = '\u202F';
const String currencySpace = '\u00A0';
const String euro = '€';

void main() {
  group('format', () {
    test('affiche deux décimales, séparateur de milliers et symbole', () {
      expect(
        MoneyFormatter.format(1234.5),
        '1${groupSeparator}234,50$currencySpace$euro',
      );
    });

    test('conserve le signe négatif de la valeur', () {
      expect(
        MoneyFormatter.format(-1234.5),
        '-1${groupSeparator}234,50$currencySpace$euro',
      );
    });

    test('arrondit au centime', () {
      expect(MoneyFormatter.format(0.005), '0,01$currencySpace$euro');
    });

    test('formate zéro', () {
      expect(MoneyFormatter.format(0), '0,00$currencySpace$euro');
    });
  });

  group('formatRounded', () {
    test('supprime les décimales', () {
      expect(
        MoneyFormatter.formatRounded(1234.5),
        '1${groupSeparator}235$currencySpace$euro',
      );
    });
  });

  group('formatPlain', () {
    test('omet le symbole et garde deux décimales', () {
      expect(MoneyFormatter.formatPlain(1234.5), '1${groupSeparator}234,50');
    });
  });

  group('formatPlainRounded', () {
    test('omet le symbole et les décimales', () {
      expect(
        MoneyFormatter.formatPlainRounded(1234.5),
        '1${groupSeparator}235',
      );
    });
  });

  group('signOf', () {
    test('rend le plus pour une valeur positive', () {
      expect(MoneyFormatter.signOf(12), MoneyFormatter.plusSign);
    });

    test('rend le plus pour zéro', () {
      expect(MoneyFormatter.signOf(0), MoneyFormatter.plusSign);
    });

    test('rend le moins typographique pour une valeur négative', () {
      expect(MoneyFormatter.signOf(-12), MoneyFormatter.minusSign);
      expect(MoneyFormatter.minusSign, '−');
    });
  });

  group('formatSigned', () {
    test('préfixe le montant absolu du signe et d une espace', () {
      expect(
        MoneyFormatter.formatSigned(1234.5),
        '+ 1${groupSeparator}234,50$currencySpace$euro',
      );
      expect(
        MoneyFormatter.formatSigned(-1234.5),
        '− 1${groupSeparator}234,50$currencySpace$euro',
      );
    });
  });

  group('splitParts', () {
    test('sépare partie entière et décimales du montant absolu', () {
      final parts = MoneyFormatter.splitParts(-1234.5);
      expect(parts.integer, '1${groupSeparator}234');
      expect(parts.decimals, '50');
    });

    test('complète les décimales manquantes', () {
      expect(MoneyFormatter.splitParts(7).decimals, '00');
    });
  });
}
