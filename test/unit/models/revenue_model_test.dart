import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/models/revenue_model.dart';

void main() {
  group('RevenueModel', () {
    test('should create instance correctly', () {
      final revenue = RevenueModel.create(
        name: 'Test',
        amount: 100,
        accountId: 1,
        date: DateTime(2024, 1, 1),
        frequency: 'Mensuel',
      );

      expect(revenue.name, 'Test');
      expect(revenue.amount, 100);
    });

    test('copyWith should update specific fields', () {
      final revenue = RevenueModel.create(
        name: 'Old',
        amount: 100,
        accountId: 1,
        date: DateTime(2024, 1, 1),
        frequency: 'Mensuel',
      );

      final updated = revenue.copyWith(name: 'New', amount: 200);

      expect(updated.name, 'New');
      expect(updated.amount, 200);
      expect(updated.accountId, 1);
    });
  });
}
