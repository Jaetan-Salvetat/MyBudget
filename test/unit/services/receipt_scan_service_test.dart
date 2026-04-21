import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/models/scanned_item_model.dart';

List<CategoryModel> _createTestCategories() {
  return [
    CategoryModel.create(name: 'Alimentation', icon: 'restaurant')..id = 1,
    CategoryModel.create(name: 'Transport', icon: 'directions_car')..id = 2,
    CategoryModel.create(name: 'Loisirs', icon: 'sports_esports')..id = 3,
    CategoryModel.create(name: 'Divers', icon: 'more_horiz')..id = 4,
  ];
}

int? _matchCategory(String? name, List<CategoryModel> categories) {
  if (name == null) return null;
  final lowerName = name.toLowerCase();
  for (final category in categories) {
    if (category.name.toLowerCase() == lowerName) {
      return category.id;
    }
  }
  return null;
}

void main() {
  group('Category matching', () {
    late List<CategoryModel> categories;

    setUp(() {
      categories = _createTestCategories();
    });

    test('matches exact category name', () {
      expect(_matchCategory('Alimentation', categories), 1);
      expect(_matchCategory('Transport', categories), 2);
    });

    test('matches case-insensitive', () {
      expect(_matchCategory('alimentation', categories), 1);
      expect(_matchCategory('TRANSPORT', categories), 2);
      expect(_matchCategory('lOiSiRs', categories), 3);
    });

    test('returns null for unknown category', () {
      expect(_matchCategory('Inconnu', categories), null);
      expect(_matchCategory('Santé', categories), null);
    });

    test('returns null for null input', () {
      expect(_matchCategory(null, categories), null);
    });
  });

  group('ScannedItemModel', () {
    test('creates with all fields', () {
      final item = ScannedItemModel(
        name: 'Pâtes',
        amount: 2.30,
        categoryName: 'Alimentation',
        categoryId: 1,
      );

      expect(item.name, 'Pâtes');
      expect(item.amount, 2.30);
      expect(item.categoryName, 'Alimentation');
      expect(item.categoryId, 1);
    });

    test('creates with nullable fields', () {
      final item = ScannedItemModel(
        name: 'Article inconnu',
        amount: 5.00,
      );

      expect(item.categoryName, null);
      expect(item.categoryId, null);
    });

    test('amount is mutable', () {
      final item = ScannedItemModel(name: 'Test', amount: 10.0);
      item.amount = 15.0;
      expect(item.amount, 15.0);
    });

    test('categoryId is mutable', () {
      final item = ScannedItemModel(name: 'Test', amount: 10.0);
      expect(item.categoryId, null);
      item.categoryId = 3;
      expect(item.categoryId, 3);
    });
  });

  group('ReceiptScanResultModel', () {
    test('creates with all fields', () {
      final result = ReceiptScanResultModel(
        storeName: 'Carrefour',
        date: DateTime(2026, 4, 21),
        items: [
          ScannedItemModel(name: 'Pâtes', amount: 2.30, categoryId: 1),
          ScannedItemModel(name: 'Essence', amount: 45.0, categoryId: 2),
        ],
      );

      expect(result.storeName, 'Carrefour');
      expect(result.date, DateTime(2026, 4, 21));
      expect(result.items.length, 2);
    });

    test('creates with nullable fields', () {
      final result = ReceiptScanResultModel(
        items: [ScannedItemModel(name: 'Test', amount: 1.0)],
      );

      expect(result.storeName, null);
      expect(result.date, null);
    });

    test('date is mutable', () {
      final result = ReceiptScanResultModel(items: []);
      expect(result.date, null);
      result.date = DateTime(2026, 1, 1);
      expect(result.date, DateTime(2026, 1, 1));
    });

    test('items list is mutable', () {
      final result = ReceiptScanResultModel(items: [
        ScannedItemModel(name: 'A', amount: 1.0),
        ScannedItemModel(name: 'B', amount: 2.0),
      ]);

      expect(result.items.length, 2);
      result.items.removeAt(0);
      expect(result.items.length, 1);
      expect(result.items.first.name, 'B');
    });
  });
}
