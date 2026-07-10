import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';

void main() {
  group('QuickAddException', () {
    test('QuickAddNoAmountException has correct message', () {
      const exception = QuickAddNoAmountException();
      expect(exception.message, 'Aucun montant détecté dans la saisie');
    });

    test('QuickAddClassificationException stores custom message', () {
      const exception = QuickAddClassificationException(message: 'Erreur');
      expect(exception.message, 'Erreur');
    });

    test('all exceptions are QuickAddException', () {
      const exceptions = <QuickAddException>[
        QuickAddNoAmountException(),
        QuickAddClassificationException(message: 'test'),
      ];

      for (final e in exceptions) {
        expect(e, isA<QuickAddException>());
        expect(e, isA<Exception>());
      }
    });
  });
}
