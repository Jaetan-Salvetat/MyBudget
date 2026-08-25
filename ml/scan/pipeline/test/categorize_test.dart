import 'dart:convert';
import 'dart:io';

import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

class _FakeClassifier implements ReceiptLineClassifier {
  final Map<String, LinePrediction> answers;
  final List<String> seen = [];

  _FakeClassifier(this.answers);

  @override
  Future<LinePrediction> classify(String normalizedLine) async {
    seen.add(normalizedLine);
    return answers[normalizedLine] ?? (slug: 'divers.autre', confidence: 0.1);
  }
}

void main() {
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

    test('keeps a line made of numbers', () {
      expect(normalizeReceiptLine('0,180 4,00'), '0,180 4,00');
    });

    test('never returns an empty string', () {
      expect(normalizeReceiptLine('***'), '***');
    });

    test('matches the Python reference on every golden line', () {
      final file = File('test/fixtures/receipt_line_normalization.json');
      final pairs = (jsonDecode(file.readAsStringSync()) as List<dynamic>)
          .cast<List<dynamic>>();
      final mismatches = <String>[
        for (final pair in pairs)
          if (normalizeReceiptLine(pair[0] as String) != pair[1])
            '${pair[0]} → "${normalizeReceiptLine(pair[0] as String)}" '
                'attendu "${pair[1]}"',
      ];
      expect(mismatches, isEmpty, reason: mismatches.take(20).join('\n'));
      expect(pairs.length, greaterThan(3000));
    });
  });

  group('ReceiptCategorizer.ticketCategory', () {
    test('trusts a confident store', () {
      final ticket = ReceiptCategorizer.ticketCategory(
        (slug: 'alimentation.supermarche', confidence: 0.9),
        [(slug: 'restauration.fast_food', confidence: 0.99)],
      );
      expect(ticket.slug, 'alimentation.supermarche');
    });

    test('falls back to the weighted vote when the store is unsure', () {
      final ticket = ReceiptCategorizer.ticketCategory(
        (slug: 'transport.transport_commun', confidence: 0.3),
        [
          (slug: 'alimentation.supermarche', confidence: 0.9),
          (slug: 'alimentation.supermarche', confidence: 0.8),
          (slug: 'restauration.fast_food', confidence: 0.95),
        ],
      );
      expect(ticket.slug, 'alimentation.supermarche');
      expect(ticket.confidence, closeTo(1.7 / 3, 1e-9));
    });

    test('votes when the store is unreadable', () {
      final ticket = ReceiptCategorizer.ticketCategory(null, [
        (slug: 'restauration.restaurant', confidence: 0.7),
      ]);
      expect(ticket.slug, 'restauration.restaurant');
    });

    test('keeps the unsure store when there is nothing to vote with', () {
      final ticket = ReceiptCategorizer.ticketCategory((
        slug: 'transport.peage',
        confidence: 0.2,
      ), const []);
      expect(ticket.slug, 'transport.peage');
    });

    test('has a fallback when nothing is known', () {
      final ticket = ReceiptCategorizer.ticketCategory(null, const []);
      expect(ticket.slug, 'divers.autre');
      expect(ticket.confidence, 0.0);
    });
  });

  group('ReceiptCategorizer.itemCategory', () {
    const supermarket = (slug: 'alimentation.supermarche', confidence: 0.9);

    test('an article follows its store by default', () {
      expect(
        ReceiptCategorizer.itemCategory(supermarket, (
          slug: 'restauration.fast_food',
          confidence: 0.99,
        )),
        'alimentation.supermarche',
      );
    });

    test('a confident distinct family leaves a food store', () {
      expect(
        ReceiptCategorizer.itemCategory(supermarket, (
          slug: 'divers.animaux',
          confidence: 0.8,
        )),
        'divers.animaux',
      );
    });

    test('an unsure distinct family stays with the store', () {
      expect(
        ReceiptCategorizer.itemCategory(supermarket, (
          slug: 'divers.animaux',
          confidence: 0.5,
        )),
        'alimentation.supermarche',
      );
    });

    test('nothing leaves a non-food store', () {
      expect(
        ReceiptCategorizer.itemCategory(
          (slug: 'logement.travaux', confidence: 0.9),
          (slug: 'shopping.mobilier_deco', confidence: 0.99),
        ),
        'logement.travaux',
      );
    });
  });

  group('ReceiptCategorizer.categorize', () {
    test('normalizes lines before the model and maps every item', () async {
      final classifier = _FakeClassifier({
        'carrefour market aytre': (
          slug: 'alimentation.supermarche',
          confidence: 0.95,
        ),
        'litiere silice pour chat u': (slug: 'divers.animaux', confidence: 0.9),
        'blc plt .f': (slug: 'restauration.fast_food', confidence: 0.7),
      });
      final result = await ReceiptCategorizer(classifier).categorize(
        store: 'CARREFOUR MARKET AYTRE',
        itemNames: ['LITIERE SILICE POUR CHAT U 5L', '*160G BLC PLT 4TR.F'],
      );

      expect(result.ticket.slug, 'alimentation.supermarche');
      expect(result.itemSlugs, ['divers.animaux', 'alimentation.supermarche']);
      expect(classifier.seen, [
        'carrefour market aytre',
        'litiere silice pour chat u',
        'blc plt .f',
      ]);
    });

    test('skips the store call when the header is unreadable', () async {
      final classifier = _FakeClassifier({
        'menu supreme': (slug: 'restauration.fast_food', confidence: 0.9),
      });
      final result = await ReceiptCategorizer(classifier)
          .categorize(store: '  ', itemNames: ['1 MENU SUPREME']);

      expect(result.ticket.slug, 'restauration.fast_food');
      expect(result.itemSlugs, ['restauration.fast_food']);
      expect(classifier.seen, ['menu supreme']);
    });
  });
}
