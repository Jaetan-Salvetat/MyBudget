import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/data/model/account_model.dart';

void main() {
  group('AccountModel', () {
    test('should create instance correctly', () {
      final account = AccountModel.create(name: 'Main Account', bank: 'Bank A');

      expect(account.name, 'Main Account');
      expect(account.bank, 'Bank A');
    });

    test('copyWith should update fields correctly', () {
      final account = AccountModel.create(name: 'Original', bank: 'Bank A')
        ..id = 1;

      final copy = account.copyWith(name: 'Updated');

      expect(copy.id, 1);
      expect(copy.name, 'Updated');
      expect(copy.bank, 'Bank A');
    });

    test('fromJson should parse json correctly', () {
      final json = {'id': '123', 'name': 'Json Account', 'bank': 'Json Bank'};

      final account = AccountModel.fromJson(json);

      expect(account.id, 123);
      expect(account.name, 'Json Account');
      expect(account.bank, 'Json Bank');
    });
  });
}
