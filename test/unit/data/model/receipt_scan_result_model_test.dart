import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/data/model/receipt_scan_result_model.dart';
import 'package:mybudget/data/model/scanned_item_model.dart';

ScannedItemModel itemOf({
  String name = 'Pain',
  double amount = 2.0,
  double discount = 0,
  String? slug = 'alimentation.boulangerie',
  double confidence = 0.9,
  bool confirmed = false,
}) {
  return ScannedItemModel(
    name: name,
    amount: amount,
    discount: discount,
    categorySlug: slug,
    categoryName: slug == null ? null : 'Boulangerie',
    categoryConfidence: confidence,
    confirmedByUser: confirmed,
  );
}

final DateTime _fixedNow = DateTime(2026, 6, 15, 9, 30);

void main() {
  group('ScannedItemModel', () {
    test('un article sans catégorie n\'est pas rangé', () {
      final item = itemOf(slug: null, confidence: 0);

      expect(item.isRanked, isFalse);
      expect(item.isCategoryUncertain, isFalse);
      expect(item.needsAttention, isTrue);
    });

    test('une confiance sous le seuil rend la catégorie incertaine', () {
      expect(itemOf(confidence: 0.4).isCategoryUncertain, isTrue);
      expect(itemOf(confidence: 0.9).isCategoryUncertain, isFalse);
    });

    test(
      'une catégorie confirmée par l\'utilisateur n\'est plus incertaine',
      () {
        final item = itemOf(confidence: 0.1, confirmed: true);

        expect(item.isCategoryUncertain, isFalse);
        expect(item.needsAttention, isFalse);
      },
    );

    test('le montant effectif retire la remise', () {
      expect(itemOf(amount: 8.90, discount: 1.50).effectiveAmount, 7.40);
    });
  });

  group('ReceiptScanResultModel', () {
    test('une date lue est conservée telle quelle', () {
      final read = DateTime(2026, 8, 31);
      final result = ReceiptScanResultModel(date: read, items: [itemOf()]);

      expect(result.date, read);
    });

    ReceiptScanResultModel resultOf({double? printedTotal}) {
      return ReceiptScanResultModel(
        date: _fixedNow,
        printedTotal: printedTotal,
        items: [
          itemOf(amount: 2.87),
          itemOf(amount: 6.54),
          itemOf(amount: 8.90, discount: 1.50),
        ],
      );
    }

    test('le total des articles somme les montants effectifs', () {
      expect(resultOf().itemsTotal, closeTo(16.81, 0.001));
    });

    test('sans total imprimé, il n\'y a pas d\'écart à annoncer', () {
      final result = resultOf();

      expect(result.gap, isNull);
      expect(result.hasGap, isFalse);
    });

    test('l\'écart est la différence avec le total imprimé, au centime', () {
      expect(resultOf(printedTotal: 18.56).gap, 1.75);
      expect(resultOf(printedTotal: 18.56).hasGap, isTrue);
    });

    test('une différence sous le centime n\'est pas un écart', () {
      final result = resultOf(printedTotal: 16.814);

      expect(result.gap, 0);
      expect(result.hasGap, isFalse);
    });

    test('les dépenses suivent l\'ordre d\'apparition des catégories', () {
      final result = ReceiptScanResultModel(
        date: _fixedNow,
        items: [
          itemOf(amount: 2.0, slug: 'maison.entretien'),
          itemOf(amount: 3.0, slug: 'alimentation.boulangerie'),
          itemOf(amount: 1.5, slug: 'maison.entretien'),
        ],
      );

      final groups = result.groupedByCategory;
      expect(groups.map((group) => group.slug), [
        'maison.entretien',
        'alimentation.boulangerie',
      ]);
      expect(groups.first.total, 3.5);
      expect(groups.first.count, 2);
    });

    test('un article non rangé ne crée aucune dépense', () {
      final result = ReceiptScanResultModel(
        date: _fixedNow,
        items: [itemOf(slug: null, confidence: 0)],
      );

      expect(result.groupedByCategory, isEmpty);
    });

    test('les articles à confirmer sont comptés', () {
      final result = ReceiptScanResultModel(
        date: _fixedNow,
        items: [
          itemOf(),
          itemOf(confidence: 0.2),
          itemOf(slug: null, confidence: 0),
        ],
      );

      expect(result.pendingCount, 2);
    });
  });
}
