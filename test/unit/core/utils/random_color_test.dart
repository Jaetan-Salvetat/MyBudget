import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/utils/random_color.dart';

void main() {
  group('la conversion TSL vers ARGB', () {
    test('rend un rouge sombre désaturé pour une teinte nulle', () {
      expect(argbFromHsl(0), 0xFF993333);
    });

    test('rend un vert pour une teinte de 120 degrés', () {
      expect(argbFromHsl(120), 0xFF339933);
    });

    test('rend un bleu pour une teinte de 240 degrés', () {
      expect(argbFromHsl(240), 0xFF333399);
    });

    test('boucle sur 360 degrés', () {
      expect(argbFromHsl(360), argbFromHsl(0));
    });
  });

  group('la couleur aléatoire de bénéficiaire', () {
    test('est toujours opaque', () {
      for (var essai = 0; essai < 200; essai++) {
        expect(randomBeneficiaryColor() >> 24 & 0xFF, 0xFF);
      }
    });

    test('varie sur plusieurs tirages', () {
      final couleurs = <int>{
        for (var essai = 0; essai < 50; essai++) randomBeneficiaryColor(),
      };

      expect(couleurs.length, greaterThan(1));
    });
  });
}
