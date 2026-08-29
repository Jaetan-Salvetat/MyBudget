import 'dart:convert';
import 'dart:io';

import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

List<List<dynamic>> _pairs(String name) =>
    (jsonDecode(File('test/fixtures/$name').readAsStringSync()) as List<dynamic>)
        .cast<List<dynamic>>();

void _expectParity(String name, String Function(String) normalize) {
  final pairs = _pairs(name);
  final mismatches = <String>[
    for (final pair in pairs)
      if (normalize(pair[0] as String) != pair[1])
        '${pair[0]} → "${normalize(pair[0] as String)}" attendu "${pair[1]}"',
  ];
  expect(mismatches, isEmpty, reason: mismatches.take(20).join('\n'));
  expect(pairs.length, greaterThan(3000));
}

void main() {
  group('normalizeQuery', () {
    test('ungluess punctuation whatever the spacing', () {
      expect(normalizeQuery('father &son'), 'father & son');
      expect(normalizeQuery('Father& Son'), 'father & son');
      expect(normalizeQuery('FATHER&SON'), 'father & son');
    });

    test('folds accents and case', () {
      expect(normalizeQuery('Marché péage crèche'), 'marche peage creche');
      expect(normalizeQuery('MARCHE PEAGE CRECHE'), 'marche peage creche');
    });

    test('folds a decomposed text', () {
      expect(normalizeQuery('cafe\u0301 de la gare'), 'cafe de la gare');
      expect(normalizeQuery('BI\u0307M'), 'bim');
    });

    test('unifies apostrophes and dashes', () {
      expect(normalizeQuery('aujourd’hui'), "aujourd'hui");
      expect(normalizeQuery('week—end'), 'week-end');
    });

    test('is idempotent', () {
      for (final text in ['Café Père & Fils !!', 'N°42 — Zalando']) {
        expect(normalizeQuery(normalizeQuery(text)), normalizeQuery(text));
      }
    });

    test('matches the Python reference on every entity name', () {
      _expectParity('query_normalization.json', normalizeQuery);
    });
  });

  group('normalizeReceiptLine', () {
    test('strips receipt noise and lowercases', () {
      expect(normalizeReceiptLine('*160G BLC PLT 4TR.F'), 'blc plt .f');
      expect(normalizeReceiptLine('*4X100G YOPA 0% LIT'), 'yopa lit');
      expect(
        normalizeReceiptLine('2120017210877 SAO PAULO DENIM BER 42'),
        'sao paulo denim ber',
      );
      expect(normalizeReceiptLine('1 MENU SUPREME'), 'menu supreme');
      expect(normalizeReceiptLine('6X1.5L EAU SOURCE'), 'eau source');
    });

    test('lands in the same canonical form as a typed query', () {
      expect(normalizeReceiptLine('*160G PÂTÉ CROÛTE'), 'pate croute');
      expect(normalizeReceiptLine('PÈRE&FILS'), normalizeQuery('Père & Fils'));
    });

    test('keeps a line made of numbers', () {
      expect(normalizeReceiptLine('0,180 4,00'), '0 , 180 4 , 00');
    });

    test('never returns an empty string', () {
      expect(normalizeReceiptLine('***'), '*');
    });

    test('matches the Python reference on every golden line', () {
      _expectParity('receipt_line_normalization.json', normalizeReceiptLine);
    });
  });
}
