import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/core/enums/frequency.dart';

void main() {
  group('ExpenseModel', () {
    test('should create a valid instance', () {
      final date = DateTime.now();
      final expense = ExpenseModel.create(
        name: 'Test Expense',
        amount: 100.0,
        categoryId: 1,
        date: date,
        frequency: 'Mensuel',
        accountId: 1,
      );

      expect(expense.name, 'Test Expense');
      expect(expense.amount, 100.0);
      expect(expense.categoryId, 1);
      expect(expense.date, date);
      expect(expense.frequency, 'Mensuel');
      expect(expense.accountId, 1);
    });

    test('copyWith should return a new instance with updated values', () {
      final expense = ExpenseModel.create(
        name: 'Original',
        amount: 50.0,
        categoryId: 1,
        date: DateTime.now(),
        frequency: 'Mensuel',
        accountId: 1,
      );

      final updated = expense.copyWith(name: 'Updated', amount: 75.0);

      expect(updated.name, 'Updated');
      expect(updated.amount, 75.0);
      expect(updated.categoryId, expense.categoryId);
    });

    test('toJson should return correct map', () {
      final date = DateTime(2023, 1, 1);
      final expense = ExpenseModel.create(
        name: 'Json Test',
        amount: 20.0,
        categoryId: 2,
        date: date,
        frequency: 'Ponctuel',
        accountId: 3,
      )..id = 10;

      final json = expense.toJson();

      expect(json['id'], '10');
      expect(json['name'], 'Json Test');
      expect(json['amount'], 20.0);
      expect(json['categoryId'], '2');
      expect(json['date'], date.toIso8601String());
      expect(json['frequency'], 'Ponctuel');
      expect(json['accountId'], '3');
    });

    test('fromJson should create correct instance', () {
      final date = DateTime(2023, 1, 1);
      final json = {
        'id': '10',
        'name': 'Json Test',
        'amount': 20.0,
        'categoryId': '2',
        'date': date.toIso8601String(),
        'frequency': 'Ponctuel',
        'accountId': '3',
      };

      final expense = ExpenseModel.fromJson(json);

      expect(expense.id, 10);
      expect(expense.name, 'Json Test');
      expect(expense.amount, 20.0);
      expect(expense.categoryId, 2);
      expect(expense.date, date);
      expect(expense.frequency, 'Ponctuel');
      expect(expense.accountId, 3);
    });

    test('frequencyEnum getter should return correct enum', () {
      final expense = ExpenseModel()..frequency = 'Mensuel';
      expect(expense.frequencyEnum, Frequency.monthly);
    });

    test('frequencyEnum setter should update frequency string', () {
      final expense = ExpenseModel();
      expense.frequencyEnum = Frequency.annual;
      expect(expense.frequency, 'Annuel');
    });
  });
}
