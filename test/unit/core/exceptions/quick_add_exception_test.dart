import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';

void main() {
  group('QuickAddException', () {
    test('porte son message dans les journaux', () {
      const exception = QuickAddClassificationException(
        message: 'Modèle incompatible : 80 classes pour 82 catégories',
      );

      expect(
        '$exception',
        'QuickAddClassificationException: '
            'Modèle incompatible : 80 classes pour 82 catégories',
      );
    });

    test('vaut aussi pour l\'absence de montant', () {
      expect(
        '${const QuickAddNoAmountException()}',
        contains('Aucun montant détecté'),
      );
    });
  });
}
