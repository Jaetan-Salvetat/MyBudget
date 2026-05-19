import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/models/quick_add_result_model.dart';

void main() {
  group('QuickAddResultModel', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'name': 'Café',
        'amount': 3.5,
        'categoryId': 1,
        'newCategory': null,
        'newCategoryIcon': null,
        'newCategoryColor': null,
        'frequency': 'Ponctuel',
      };

      final result = QuickAddResultModel.fromJson(json);

      expect(result.name, 'Café');
      expect(result.amount, 3.5);
      expect(result.categoryId, 1);
      expect(result.newCategory, isNull);
      expect(result.newCategoryIcon, isNull);
      expect(result.newCategoryColor, isNull);
      expect(result.frequency, 'Ponctuel');
    });

    test('fromJson handles newCategory with icon and color', () {
      final json = {
        'name': 'Cadeau maman',
        'amount': 20.0,
        'categoryId': null,
        'newCategory': 'Cadeaux',
        'newCategoryIcon': 'card_giftcard',
        'newCategoryColor': '#EC407A',
        'frequency': 'Ponctuel',
      };

      final result = QuickAddResultModel.fromJson(json);

      expect(result.categoryId, isNull);
      expect(result.newCategory, 'Cadeaux');
      expect(result.newCategoryIcon, 'card_giftcard');
      expect(result.newCategoryColor, '#EC407A');
    });

    test('fromJson handles integer amount', () {
      final json = {
        'name': 'Loyer',
        'amount': 800,
        'categoryId': 2,
        'newCategory': null,
        'newCategoryIcon': null,
        'newCategoryColor': null,
        'frequency': 'Mensuel',
      };

      final result = QuickAddResultModel.fromJson(json);

      expect(result.amount, 800.0);
    });

    test('copyWith replaces specified fields', () {
      const original = QuickAddResultModel(
        name: 'Café',
        amount: 3.5,
        frequency: 'Ponctuel',
        categoryId: 1,
      );

      final modified = original.copyWith(amount: 4.0, name: 'Thé');

      expect(modified.name, 'Thé');
      expect(modified.amount, 4.0);
      expect(modified.categoryId, 1);
      expect(modified.frequency, 'Ponctuel');
    });

    test('copyWith preserves unspecified fields', () {
      const original = QuickAddResultModel(
        name: 'Café',
        amount: 3.5,
        frequency: 'Ponctuel',
        newCategory: 'Boissons',
        newCategoryIcon: 'local_cafe',
        newCategoryColor: '#8D6E63',
      );

      final modified = original.copyWith(amount: 5.0);

      expect(modified.name, 'Café');
      expect(modified.newCategory, 'Boissons');
      expect(modified.newCategoryIcon, 'local_cafe');
      expect(modified.newCategoryColor, '#8D6E63');
      expect(modified.frequency, 'Ponctuel');
    });
  });
}
