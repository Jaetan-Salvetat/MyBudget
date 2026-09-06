import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/constants/receipt_schema.dart';
import 'package:mybudget/data/service/scan/receipt_read_parser.dart';

String dateSection(Object? value) => jsonEncode({ReceiptSchema.dateKey: value});

void main() {
  group('sectionDateOf', () {
    test('une date ISO passe telle quelle', () {
      expect(sectionDateOf(dateSection('2017-02-24')), '2017-02-24');
    });

    test('une date française est acceptée et convertie en ISO', () {
      expect(sectionDateOf(dateSection('24/02/2017')), '2017-02-24');
      expect(sectionDateOf(dateSection('24-02-2017')), '2017-02-24');
      expect(sectionDateOf(dateSection('24.02.2017')), '2017-02-24');
    });

    test('un jour ou un mois sur un seul chiffre est accepté', () {
      expect(sectionDateOf(dateSection('3/4/2026')), '2026-04-03');
    });

    test('une année sur deux chiffres est celle de ce siècle', () {
      expect(sectionDateOf(dateSection('24/02/17')), '2017-02-24');
      expect(sectionDateOf(dateSection('01/09/26')), '2026-09-01');
    });

    test('les espaces autour ne gênent pas', () {
      expect(sectionDateOf(dateSection('  24/02/2017 ')), '2017-02-24');
    });

    test('une date qui n\'existe pas est écartée', () {
      expect(sectionDateOf(dateSection('31/02/2026')), isNull);
      expect(sectionDateOf(dateSection('2026-02-31')), isNull);
      expect(sectionDateOf(dateSection('00/01/2026')), isNull);
      expect(sectionDateOf(dateSection('24/13/2026')), isNull);
    });

    test('le jour et le mois ne sont jamais intervertis', () {
      expect(
        sectionDateOf(dateSection('04/03/2026')),
        '2026-03-04',
        reason: 'le format français se lit jour en premier',
      );
    });

    test('ce qui n\'est pas une date reste écarté', () {
      expect(sectionDateOf(dateSection('hier')), isNull);
      expect(sectionDateOf(dateSection('24 février 2017')), isNull);
      expect(sectionDateOf(dateSection('')), isNull);
      expect(sectionDateOf(dateSection(null)), isNull);
      expect(sectionDateOf(dateSection(20170224)), isNull);
      expect(sectionDateOf('pas du json'), isNull);
    });
  });
}
