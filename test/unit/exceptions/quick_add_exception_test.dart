import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';

void main() {
  group('QuickAddException', () {
    test('QuickAddNetworkException has correct message', () {
      const exception = QuickAddNetworkException();
      expect(exception.message, 'Pas de connexion internet');
    });

    test('QuickAddApiException stores custom message', () {
      const exception = QuickAddApiException(message: 'Erreur 500');
      expect(exception.message, 'Erreur 500');
    });

    test('QuickAddParseException has correct message', () {
      const exception = QuickAddParseException();
      expect(exception.message, 'Impossible d\'analyser la dépense');
    });

    test('QuickAddRateLimitException stores remaining count', () {
      const exception = QuickAddRateLimitException(remaining: 0);
      expect(exception.message, 'Limite mensuelle atteinte');
      expect(exception.remaining, 0);
    });

    test('all exceptions are QuickAddException', () {
      const exceptions = <QuickAddException>[
        QuickAddNetworkException(),
        QuickAddApiException(message: 'test'),
        QuickAddParseException(),
        QuickAddRateLimitException(remaining: 5),
      ];

      for (final e in exceptions) {
        expect(e, isA<QuickAddException>());
        expect(e, isA<Exception>());
      }
    });
  });
}
