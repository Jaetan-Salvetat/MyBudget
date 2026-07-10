import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/models/quick_add_result_model.dart';

void main() {
  group('QuickAddResultModel', () {
    test('copyWith replaces specified fields', () {
      const original = QuickAddResultModel(
        type: TransactionType.expense,
        name: 'Café',
        amount: 3.5,
        frequency: 'Ponctuel',
        categoryId: 1,
      );

      final modified = original.copyWith(amount: 4.0, name: 'Thé');

      expect(modified.type, TransactionType.expense);
      expect(modified.name, 'Thé');
      expect(modified.amount, 4.0);
      expect(modified.categoryId, 1);
      expect(modified.frequency, 'Ponctuel');
    });

    test('copyWith preserves unspecified fields', () {
      const original = QuickAddResultModel(
        type: TransactionType.expense,
        name: 'Café',
        amount: 3.5,
        frequency: 'Ponctuel',
        newCategory: 'Restauration',
        newCategoryIcon: 'restaurant',
        newCategoryColor: 0xFFF44336,
      );

      final modified = original.copyWith(amount: 5.0);

      expect(modified.name, 'Café');
      expect(modified.newCategory, 'Restauration');
      expect(modified.newCategoryIcon, 'restaurant');
      expect(modified.newCategoryColor, 0xFFF44336);
      expect(modified.frequency, 'Ponctuel');
    });

    test('copyWith can change transaction type', () {
      const original = QuickAddResultModel(
        type: TransactionType.expense,
        name: 'Salaire',
        amount: 2500,
        frequency: 'Mensuel',
      );

      final modified = original.copyWith(type: TransactionType.income);

      expect(modified.type, TransactionType.income);
      expect(modified.name, 'Salaire');
    });
  });
}
