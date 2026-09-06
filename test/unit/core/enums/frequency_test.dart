import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';

void main() {
  group('storageKey', () {
    test('ne dépend pas de la langue', () {
      expect(Frequency.monthly.storageKey, 'monthly');
      expect(Frequency.annual.storageKey, 'annual');
      expect(Frequency.oneTime.storageKey, 'oneTime');
    });

    test('reste distinct du libellé affiché', () {
      for (final frequency in Frequency.values) {
        expect(frequency.storageKey, isNot(frequency.label));
      }
    });
  });

  group('fromStorage', () {
    test('relit chaque clé écrite', () {
      for (final frequency in Frequency.values) {
        expect(Frequency.fromStorage(frequency.storageKey), frequency);
      }
    });

    test('relit les libellés français des données antérieures', () {
      expect(Frequency.fromStorage('Mensuel'), Frequency.monthly);
      expect(Frequency.fromStorage('Annuel'), Frequency.annual);
      expect(Frequency.fromStorage('Ponctuel'), Frequency.oneTime);
    });

    test('retombe sur mensuel pour une valeur inconnue', () {
      expect(Frequency.fromStorage(''), Frequency.monthly);
      expect(Frequency.fromStorage('hebdomadaire'), Frequency.monthly);
    });
  });

  group('label', () {
    test('donne le libellé français', () {
      expect(Frequency.monthly.label, 'Mensuel');
      expect(Frequency.annual.label, 'Annuel');
      expect(Frequency.oneTime.label, 'Ponctuel');
    });
  });
}
