import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';

void main() {
  group('ScanException', () {
    test('photo illisible dit quoi refaire', () {
      const exception = ScanUnreadableException();
      expect(exception.message, 'Aucun texte lisible sur cette photo');
    });

    test('ticket sans article est distingué d\'une photo illisible', () {
      expect(
        const ScanNoItemsException().message,
        isNot(const ScanUnreadableException().message),
      );
    });

    test('erreur générique porte son propre message', () {
      const exception = ScanGenericException(message: 'Modèle absent');
      expect(exception.message, 'Modèle absent');
    });

    test('toutes les erreurs de scan sont locales', () {
      const errors = <ScanException>[
        ScanUnreadableException(),
        ScanNoItemsException(),
        ScanGenericException(message: 'x'),
      ];
      for (final error in errors) {
        expect(error, isA<Exception>());
        expect(error.message, isNotEmpty);
      }
    });
  });
}
