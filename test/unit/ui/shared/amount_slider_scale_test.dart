import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/shared/amount_slider_scale.dart';

void main() {
  group('AmountSliderScale.forHighest', () {
    test('falls back to a usable scale when there is nothing to show', () {
      final scale = AmountSliderScale.forHighest(0);

      expect(scale.ceiling, AmountSliderScale.fallbackCeiling);
      expect(scale.divisions, greaterThan(0));
    });

    test('never sits below the highest amount', () {
      for (final highest in [3.5, 87.0, 350.0, 1234.56, 12000.0, 98765.4]) {
        expect(
          AmountSliderScale.forHighest(highest).ceiling,
          greaterThanOrEqualTo(highest),
        );
      }
    });

    test('rounds the ceiling up to a readable step', () {
      expect(AmountSliderScale.forHighest(1234.56).ceiling, 1240);
      expect(AmountSliderScale.forHighest(87).ceiling, 87);
      expect(AmountSliderScale.forHighest(350).ceiling, 350);
    });

    test('keeps the step count workable whatever the magnitude', () {
      for (final highest in [3.5, 87.0, 1234.56, 98765.4]) {
        final divisions = AmountSliderScale.forHighest(highest).divisions;

        expect(divisions, greaterThanOrEqualTo(1));
        expect(divisions, lessThanOrEqualTo(100));
      }
    });

    test('ignores a negative highest amount', () {
      expect(
        AmountSliderScale.forHighest(-10).ceiling,
        AmountSliderScale.fallbackCeiling,
      );
    });
  });

  group('AmountSliderScale.clamp', () {
    test('keeps a range that already fits', () {
      final scale = AmountSliderScale.forHighest(1000);

      expect(scale.clamp(100, 900), (100.0, 900.0));
    });

    test('pulls a stale range back under the ceiling', () {
      final scale = AmountSliderScale.forHighest(500);

      final (min, max) = scale.clamp(9000, 12000);

      expect(min, scale.ceiling);
      expect(max, scale.ceiling);
    });

    test('defaults a missing bound to the edge', () {
      final scale = AmountSliderScale.forHighest(500);

      expect(scale.clamp(null, null), (0.0, scale.ceiling));
    });
  });
}
