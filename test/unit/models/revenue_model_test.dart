import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/models/revenue_model.dart';

void main() {
  group('RevenueModel', () {
    test('should create instance correctly', () {
      final revenue = RevenueModel.create(
        name: 'Test',
        amount: 100,
        accountId: 1,
        startDate: DateTime(2024, 1, 1),
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
        startDate: DateTime(2024, 1, 1),
        frequency: 'Mensuel',
      );

      final updated = revenue.copyWith(name: 'New', amount: 200);

      expect(updated.name, 'New');
      expect(updated.amount, 200);
      expect(updated.accountId, 1);
    });

    test('copyWith should update frequency', () {
      final revenue = RevenueModel.create(
        name: 'Test',
        amount: 100,
        accountId: 1,
        startDate: DateTime(2024, 1, 1),
        frequency: 'Mensuel',
      );

      final updated = revenue.copyWith(frequency: 'Annuel');

      expect(updated.frequency, 'Annuel');
      expect(updated.name, 'Test');
    });

    test('frequencyEnum getter returns correct enum', () {
      final monthly = RevenueModel.create(
        name: 'M', amount: 100, accountId: 1,
        startDate: DateTime(2024, 1, 1), frequency: 'Mensuel',
      );
      final annual = RevenueModel.create(
        name: 'A', amount: 100, accountId: 1,
        startDate: DateTime(2024, 1, 1), frequency: 'Annuel',
      );
      final oneTime = RevenueModel.create(
        name: 'O', amount: 100, accountId: 1,
        startDate: DateTime(2024, 1, 1), frequency: 'Ponctuel',
      );

      expect(monthly.frequency, 'Mensuel');
      expect(annual.frequency, 'Annuel');
      expect(oneTime.frequency, 'Ponctuel');
    });

    test('toJson includes frequency', () {
      final revenue = RevenueModel.create(
        name: 'Test',
        amount: 100,
        accountId: 1,
        startDate: DateTime(2024, 1, 1),
        frequency: 'Annuel',
      );

      final json = revenue.toJson();

      expect(json['frequency'], 'Annuel');
    });

    test('fromJson with frequency', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'amount': 100.0,
        'accountId': '1',
        'startDate': '2024-01-01T00:00:00.000',
        'frequency': 'Ponctuel',
      };

      final revenue = RevenueModel.fromJson(json);

      expect(revenue.frequency, 'Ponctuel');
    });

    test('fromJson without frequency defaults to Mensuel', () {
      final json = {
        'id': '1',
        'name': 'Old Revenue',
        'amount': 100.0,
        'accountId': '1',
        'startDate': '2024-01-01T00:00:00.000',
      };

      final revenue = RevenueModel.fromJson(json);

      expect(revenue.frequency, 'Mensuel');
    });

    test('copyWith with endDate and parentId using sentinel pattern', () {
      final original = RevenueModel.create(
        name: 'Test',
        amount: 100,
        accountId: 1,
        startDate: DateTime(2024, 1, 1),
        frequency: 'Mensuel',
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
      final revenue = RevenueModel.create(
        name: 'Test',
        amount: 100,
        accountId: 1,
        startDate: DateTime(2024, 1, 1),
        frequency: 'Mensuel',
        endDate: DateTime(2024, 6, 15),
        parentId: 3,
      )..id = 1;

      final json = revenue.toJson();

      expect(json['endDate'], DateTime(2024, 6, 15).toIso8601String());
      expect(json['parentId'], '3');
    });

    test('toJson with null endDate and parentId', () {
      final revenue = RevenueModel.create(
        name: 'Test',
        amount: 100,
        accountId: 1,
        startDate: DateTime(2024, 1, 1),
        frequency: 'Mensuel',
      );

      final json = revenue.toJson();

      expect(json['endDate'], isNull);
      expect(json['parentId'], isNull);
    });

    test('fromJson parses endDate and parentId', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'amount': 100.0,
        'accountId': '1',
        'startDate': '2024-01-01T00:00:00.000',
        'endDate': '2024-06-15T00:00:00.000',
        'parentId': '3',
        'frequency': 'Mensuel',
      };

      final revenue = RevenueModel.fromJson(json);

      expect(revenue.endDate, DateTime(2024, 6, 15));
      expect(revenue.parentId, 3);
    });

    test('fromJson with null endDate and parentId', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'amount': 100.0,
        'accountId': '1',
        'startDate': '2024-01-01T00:00:00.000',
        'frequency': 'Mensuel',
      };

      final revenue = RevenueModel.fromJson(json);

      expect(revenue.endDate, isNull);
      expect(revenue.parentId, isNull);
    });

    test('fromJson falls back on date key when startDate is missing', () {
      final json = {
        'id': '1',
        'name': 'Legacy',
        'amount': 100.0,
        'accountId': '1',
        'date': '2024-03-20T00:00:00.000',
        'frequency': 'Mensuel',
      };

      final revenue = RevenueModel.fromJson(json);

      expect(revenue.startDate, DateTime(2024, 3, 20));
    });
  });
}
