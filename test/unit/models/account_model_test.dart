import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/models/account_model.dart';

void main() {
  group('AccountModel', () {
    test('should create a valid instance', () {
      final account = AccountModel.create(name: 'Checking', bank: 'Bank A');

      expect(account.name, 'Checking');
      expect(account.bank, 'Bank A');
    });

    test('copyWith should return a new instance with updated values', () {
      final account = AccountModel.create(name: 'Original', bank: 'Bank A');

      final updated = account.copyWith(name: 'Updated');

      expect(updated.name, 'Updated');
      expect(updated.bank, 'Bank A'); // Unchanged
    });

    test('toJson should return correct map', () {
      final account = AccountModel.create(name: 'Json Test', bank: 'Bank B')
        ..id = 10;

      final json = account.toJson();

      expect(json['id'], '10');
      expect(json['name'], 'Json Test');
      expect(json['bank'], 'Bank B');
    });

    test('fromJson should create correct instance', () {
      final json = {'id': '10', 'name': 'Json Test', 'bank': 'Bank B'};

      final account = AccountModel.fromJson(json);

      expect(account.id, 10);
      expect(account.name, 'Json Test');
      expect(account.bank, 'Bank B');
    });
  });
}
