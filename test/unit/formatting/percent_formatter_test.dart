import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/formatting/percent_formatter.dart';

const String symbolSpace = '\u00A0';

void main() {
  test('formatRate garde deux décimales et le séparateur français', () {
    expect(PercentFormatter.formatRate(3.25), '3,25$symbolSpace%');
  });

  test('formatRate complète les décimales manquantes', () {
    expect(PercentFormatter.formatRate(4), '4,00$symbolSpace%');
  });

  test('formatWhole ne montre aucune décimale', () {
    expect(PercentFormatter.formatWhole(50), '50$symbolSpace%');
  });

  test('formatShare convertit une part en points', () {
    expect(PercentFormatter.formatShare(0.634), '63$symbolSpace%');
  });

  test('formatShare arrondit au point le plus proche', () {
    expect(PercentFormatter.formatShare(0.635), '64$symbolSpace%');
  });
}
