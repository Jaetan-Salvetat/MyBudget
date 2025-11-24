import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/core/enums/frequency.dart';

void main() {
  group('ExpenseModel', () {
    test('should map Frequency enum to string correctly', () {
      final expense = ExpenseModel.create(
        name: 'Test',
        amount: 100,
        categoryId: 1,
        date: DateTime.now(),
        frequency: 'Mensuel',
        accountId: 1,
      );

      expect(expense.frequencyEnum, Frequency.monthly);

      expense.frequencyEnum = Frequency.annual;
      expect(expense.frequency, 'Annuel');
    });

    test('copyWith should preserve other fields', () {
      final original = ExpenseModel.create(
        name: 'Original',
        amount: 100,
        categoryId: 1,
        date: DateTime(2024, 1, 1),
        frequency: 'Mensuel',
        accountId: 1,
      )..id = 5;

      final copy = original.copyWith(name: 'Copy');

      expect(copy.id, 5);
      expect(copy.name, 'Copy');
      expect(copy.amount, 100);
      expect(copy.frequency, 'Mensuel');
    });
  });
}
