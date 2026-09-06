import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/data/model/expense_model.dart';

final DateTime _fixedNow = DateTime(2026, 6, 15, 9, 30);

void main() {
  group('ExpenseModel', () {
    test('should map Frequency enum to string correctly', () {
      final expense = ExpenseModel.create(
        name: 'Test',
        amount: 100,
        categorySlug: 'restauration.cafe',
        startDate: DateTime.now(),
        frequency: Frequency.monthly,
        accountId: 1,
      );

      expect(expense.frequencyEnum, Frequency.monthly);

      expense.frequencyEnum = Frequency.annual;
      expect(expense.frequency, Frequency.annual.storageKey);
    });

    test('copyWith should preserve other fields', () {
      final original = ExpenseModel.create(
        name: 'Original',
        amount: 100,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(2024, 1, 1),
        frequency: Frequency.monthly,
        accountId: 1,
      )..id = 5;

      final copy = original.copyWith(name: 'Copy');

      expect(copy.id, 5);
      expect(copy.name, 'Copy');
      expect(copy.amount, 100);
      expect(copy.frequency, Frequency.monthly.storageKey);
    });

    test('copyWith with endDate and parentId using sentinel pattern', () {
      final original = ExpenseModel.create(
        name: 'Test',
        amount: 100,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(2024, 1, 1),
        frequency: Frequency.monthly,
        accountId: 1,
      )..id = 1;

      final withValues = original.copyWith(
        endDate: DateTime(2024, 6, 15),
        parentId: 5,
      );
      expect(withValues.endDate, DateTime(2024, 6, 15));
      expect(withValues.parentId, 5);

      final withNull = withValues.copyWith(endDate: null, parentId: null);
      expect(withNull.endDate, isNull);
      expect(withNull.parentId, isNull);

      final preserved = withValues.copyWith(name: 'Changed');
      expect(preserved.endDate, DateTime(2024, 6, 15));
      expect(preserved.parentId, 5);
    });

    test('toJson includes endDate and parentId', () {
      final expense = ExpenseModel.create(
        name: 'Test',
        amount: 100,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(2024, 1, 1),
        frequency: Frequency.monthly,
        accountId: 1,
        endDate: DateTime(2024, 6, 15),
        parentId: 3,
      )..id = 1;

      final json = expense.toJson();

      expect(json['endDate'], DateTime(2024, 6, 15).toIso8601String());
      expect(json['parentId'], '3');
    });

    test('toJson with null endDate and parentId', () {
      final expense = ExpenseModel.create(
        name: 'Test',
        amount: 100,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(2024, 1, 1),
        frequency: Frequency.monthly,
        accountId: 1,
      );

      final json = expense.toJson();

      expect(json['endDate'], isNull);
      expect(json['parentId'], isNull);
    });

    test('fromJson parses endDate and parentId', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'amount': 100.0,
        'categoryId': '1',
        'startDate': '2024-01-01T00:00:00.000',
        'endDate': '2024-06-15T00:00:00.000',
        'parentId': '3',
        'frequency': 'Mensuel',
        'accountId': '1',
      };

      final expense = ExpenseModel.fromJson(json, now: _fixedNow);

      expect(expense.endDate, DateTime(2024, 6, 15));
      expect(expense.parentId, 3);
    });

    test('fromJson with null endDate and parentId', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'amount': 100.0,
        'categoryId': '1',
        'startDate': '2024-01-01T00:00:00.000',
        'frequency': 'Mensuel',
        'accountId': '1',
      };

      final expense = ExpenseModel.fromJson(json, now: _fixedNow);

      expect(expense.endDate, isNull);
      expect(expense.parentId, isNull);
    });

    test('copyWith with receiptPath using sentinel pattern', () {
      final original = ExpenseModel.create(
        name: 'Test',
        amount: 100,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(2024, 1, 1),
        frequency: Frequency.oneTime,
        accountId: 1,
      );

      final withReceipt = original.copyWith(
        receiptPath: '/path/to/receipt.jpg',
      );
      expect(withReceipt.receiptPath, '/path/to/receipt.jpg');

      final withNull = withReceipt.copyWith(receiptPath: null);
      expect(withNull.receiptPath, isNull);

      final preserved = withReceipt.copyWith(name: 'Changed');
      expect(preserved.receiptPath, '/path/to/receipt.jpg');
    });

    test('toJson includes receiptPath', () {
      final expense = ExpenseModel.create(
        name: 'Ticket Carrefour',
        amount: 50,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(2024, 1, 1),
        frequency: Frequency.oneTime,
        accountId: 1,
        receiptPath: '/receipts/123.jpg',
      );

      final json = expense.toJson();
      expect(json['receiptPath'], '/receipts/123.jpg');
    });

    test('toJson with null receiptPath', () {
      final expense = ExpenseModel.create(
        name: 'Test',
        amount: 100,
        categorySlug: 'restauration.cafe',
        startDate: DateTime(2024, 1, 1),
        frequency: Frequency.monthly,
        accountId: 1,
      );

      final json = expense.toJson();
      expect(json['receiptPath'], isNull);
    });

    test('fromJson parses receiptPath', () {
      final json = {
        'id': '1',
        'name': 'Ticket',
        'amount': 50.0,
        'categoryId': '1',
        'startDate': '2024-01-01T00:00:00.000',
        'frequency': 'Ponctuel',
        'accountId': '1',
        'receiptPath': '/receipts/123.jpg',
      };

      final expense = ExpenseModel.fromJson(json, now: _fixedNow);
      expect(expense.receiptPath, '/receipts/123.jpg');
    });

    test('fromJson with null receiptPath', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'amount': 100.0,
        'categoryId': '1',
        'startDate': '2024-01-01T00:00:00.000',
        'frequency': 'Mensuel',
        'accountId': '1',
      };

      final expense = ExpenseModel.fromJson(json, now: _fixedNow);
      expect(expense.receiptPath, isNull);
    });

    test('fromJson falls back on date key when startDate is missing', () {
      final json = {
        'id': '1',
        'name': 'Legacy',
        'amount': 100.0,
        'categoryId': '1',
        'date': '2024-03-20T00:00:00.000',
        'frequency': 'Mensuel',
        'accountId': '1',
      };

      final expense = ExpenseModel.fromJson(json, now: _fixedNow);

      expect(expense.startDate, DateTime(2024, 3, 20));
    });
  });
}
