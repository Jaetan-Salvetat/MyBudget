import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/utils/json_fields.dart';

void main() {
  group('readString', () {
    test('renvoie la chaine presente', () {
      expect(
        <String, dynamic>{'name': 'Loyer'}.readString('name', 'x'),
        'Loyer',
      );
    });

    test('convertit une valeur non textuelle', () {
      expect(<String, dynamic>{'name': 42}.readString('name', 'x'), '42');
    });

    test('retombe sur le defaut quand la cle manque', () {
      expect(<String, dynamic>{}.readString('name', 'x'), 'x');
    });

    test('retombe sur le defaut quand la valeur est nulle', () {
      expect(<String, dynamic>{'name': null}.readString('name', 'x'), 'x');
    });
  });

  group('readOptionalString', () {
    test('renvoie la chaine presente', () {
      expect(
        <String, dynamic>{'slug': 'courses'}.readOptionalString('slug'),
        'courses',
      );
    });

    test('renvoie null pour une valeur non textuelle', () {
      expect(<String, dynamic>{'slug': 7}.readOptionalString('slug'), isNull);
    });

    test('renvoie null quand la cle manque', () {
      expect(<String, dynamic>{}.readOptionalString('slug'), isNull);
    });
  });

  group('readDouble', () {
    test('renvoie un nombre entier converti', () {
      expect(<String, dynamic>{'amount': 12}.readDouble('amount', 0), 12.0);
    });

    test('renvoie un nombre decimal', () {
      expect(<String, dynamic>{'amount': 12.5}.readDouble('amount', 0), 12.5);
    });

    test('analyse une chaine numerique', () {
      expect(<String, dynamic>{'amount': '12.5'}.readDouble('amount', 0), 12.5);
    });

    test('retombe sur le defaut pour une chaine non numerique', () {
      expect(<String, dynamic>{'amount': 'abc'}.readDouble('amount', 3), 3.0);
    });

    test('retombe sur le defaut quand la cle manque', () {
      expect(<String, dynamic>{}.readDouble('amount', 3), 3.0);
    });
  });

  group('readOptionalInt', () {
    test('renvoie un entier', () {
      expect(<String, dynamic>{'id': 4}.readOptionalInt('id'), 4);
    });

    test('analyse une chaine entiere', () {
      expect(<String, dynamic>{'id': '4'}.readOptionalInt('id'), 4);
    });

    test('tronque un nombre decimal', () {
      expect(<String, dynamic>{'id': 4.9}.readOptionalInt('id'), 4);
    });

    test('renvoie null pour une chaine non numerique', () {
      expect(<String, dynamic>{'id': 'abc'}.readOptionalInt('id'), isNull);
    });

    test('renvoie null quand la cle manque', () {
      expect(<String, dynamic>{}.readOptionalInt('id'), isNull);
    });
  });

  group('readInt', () {
    test('renvoie la valeur analysee', () {
      expect(<String, dynamic>{'accountId': '9'}.readInt('accountId', 0), 9);
    });

    test('retombe sur le defaut quand la valeur est illisible', () {
      expect(<String, dynamic>{'accountId': 'abc'}.readInt('accountId', 7), 7);
    });
  });

  group('readOptionalDate', () {
    test('analyse une date ISO', () {
      expect(
        <String, dynamic>{
          'at': '2026-09-06T00:00:00.000',
        }.readOptionalDate('at'),
        DateTime(2026, 9, 6),
      );
    });

    test('renvoie null pour une date invalide', () {
      expect(<String, dynamic>{'at': 'hier'}.readOptionalDate('at'), isNull);
    });

    test('renvoie null quand la cle manque', () {
      expect(<String, dynamic>{}.readOptionalDate('at'), isNull);
    });
  });

  group('readFirstDate', () {
    test('prend la premiere cle renseignee', () {
      expect(
        <String, dynamic>{
          'startDate': '2026-09-06T00:00:00.000',
          'date': '2020-01-01T00:00:00.000',
        }.readFirstDate(const ['startDate', 'date']),
        DateTime(2026, 9, 6),
      );
    });

    test('bascule sur la cle suivante', () {
      expect(
        <String, dynamic>{
          'date': '2020-01-01T00:00:00.000',
        }.readFirstDate(const ['startDate', 'date']),
        DateTime(2020),
      );
    });

    test('renvoie null quand aucune cle ne porte de date', () {
      expect(
        <String, dynamic>{}.readFirstDate(const ['startDate', 'date']),
        isNull,
      );
    });
  });
}
