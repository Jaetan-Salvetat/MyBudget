import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/models/quick_add_result_model.dart';

void main() {
  group('QuickAddResultModel', () {
    test('needsCategoryConfirmation below the confidence threshold', () {
      const low = QuickAddResultModel(
        type: TransactionType.expense,
        name: 'Café',
        amount: 3.5,
        frequency: 'Ponctuel',
        categorySlug: 'restauration.cafe',
        categoryConfidence: 0.4,
      );

      expect(low.needsCategoryConfirmation, isTrue);
      expect(low.copyWith(categoryConfidence: 0.9).needsCategoryConfirmation,
          isFalse);
    });

    test('the threshold applies to income too', () {
      const income = QuickAddResultModel(
        type: TransactionType.income,
        name: 'Salaire',
        amount: 2500,
        frequency: 'Mensuel',
        categorySlug: 'salaire.salaire_net',
        categoryConfidence: 0.1,
      );

      expect(income.needsCategoryConfirmation, isTrue);
      expect(income.copyWith(categoryConfidence: 0.9).needsCategoryConfirmation,
          isFalse);
    });

    test('copyWith replaces specified fields', () {
      const original = QuickAddResultModel(
        type: TransactionType.expense,
        name: 'Café',
        amount: 3.5,
        frequency: 'Ponctuel',
        categorySlug: 'restauration.cafe',
      );

      final modified = original.copyWith(amount: 4.0, name: 'Thé');

      expect(modified.type, TransactionType.expense);
      expect(modified.name, 'Thé');
      expect(modified.amount, 4.0);
      expect(modified.categorySlug, 'restauration.cafe');
      expect(modified.frequency, 'Ponctuel');
    });

    test('copyWith preserves unspecified fields', () {
      const original = QuickAddResultModel(
        type: TransactionType.expense,
        name: 'Café',
        amount: 3.5,
        frequency: 'Ponctuel',
      );

      final modified = original.copyWith(amount: 5.0);

      expect(modified.name, 'Café');
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
