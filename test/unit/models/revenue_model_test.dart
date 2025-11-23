import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/models/revenue_model.dart';

void main() {
  group('RevenueModel', () {
    test('should create a valid instance', () {
      final date = DateTime.now();
      final revenue = RevenueModel.create(
        name: 'Salary',
        amount: 2000.0,
        isRegular: true,
        date: date,
        accountId: 1,
      );

      expect(revenue.name, 'Salary');
      expect(revenue.amount, 2000.0);
      expect(revenue.isRegular, true);
      expect(revenue.date, date);
      expect(revenue.accountId, 1);
    });

    test('copyWith should return a new instance with updated values', () {
      final revenue = RevenueModel.create(
        name: 'Original',
        amount: 100.0,
        isRegular: false,
        date: DateTime.now(),
        accountId: 1,
      );

      final updated = revenue.copyWith(name: 'Updated', amount: 150.0);

      expect(updated.name, 'Updated');
      expect(updated.amount, 150.0);
      expect(updated.isRegular, revenue.isRegular); // Unchanged
    });

    test('toJson should return correct map', () {
      final date = DateTime(2023, 1, 1);
      final revenue = RevenueModel.create(
        name: 'Json Test',
        amount: 50.0,
        isRegular: true,
        date: date,
        accountId: 2,
      )..id = 5;

      final json = revenue.toJson();

      expect(json['id'], '5');
      expect(json['name'], 'Json Test');
      expect(json['amount'], 50.0);
      expect(json['isRegular'], true);
      expect(json['date'], date.toIso8601String());
      expect(json['accountId'], '2');
    });

    test('fromJson should create correct instance', () {
      final date = DateTime(2023, 1, 1);
      final json = {
        'id': '5',
        'name': 'Json Test',
        'amount': 50.0,
        'isRegular': true,
        'date': date.toIso8601String(),
        'accountId': '2',
      };

      final revenue = RevenueModel.fromJson(json);

      expect(revenue.id, 5);
      expect(revenue.name, 'Json Test');
      expect(revenue.amount, 50.0);
      expect(revenue.isRegular, true);
      expect(revenue.date, date);
      expect(revenue.accountId, 2);
    });
  });
}
