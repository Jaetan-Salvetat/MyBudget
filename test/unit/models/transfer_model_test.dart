import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/models/transfer_model.dart';
import 'package:mybudget/core/enums/frequency.dart';

void main() {
  group('TransferModel', () {
    test('should map Frequency enum to string correctly', () {
      final transfer = TransferModel.create(
        name: 'Virement test',
        amount: 500,
        fromAccountId: 1,
        toAccountId: 2,
        date: DateTime.now(),
        frequency: 'Mensuel',
      );

      expect(transfer.frequencyEnum, Frequency.monthly);

      transfer.frequencyEnum = Frequency.annual;
      expect(transfer.frequency, 'Annuel');
    });

    test('copyWith should preserve other fields', () {
      final original = TransferModel.create(
        name: 'Original',
        amount: 300,
        fromAccountId: 1,
        toAccountId: 2,
        date: DateTime(2024, 6, 15),
        frequency: 'Mensuel',
      )..id = 7;

      final copy = original.copyWith(name: 'Modifié');

      expect(copy.id, 7);
      expect(copy.name, 'Modifié');
      expect(copy.amount, 300);
      expect(copy.fromAccountId, 1);
      expect(copy.toAccountId, 2);
      expect(copy.frequency, 'Mensuel');
    });

    test('copyWith should override specified fields', () {
      final original = TransferModel.create(
        name: 'Original',
        amount: 300,
        fromAccountId: 1,
        toAccountId: 2,
        date: DateTime(2024, 6, 15),
        frequency: 'Mensuel',
      );

      final copy = original.copyWith(
        amount: 600,
        fromAccountId: 3,
        toAccountId: 4,
        frequency: 'Annuel',
      );

      expect(copy.name, 'Original');
      expect(copy.amount, 600);
      expect(copy.fromAccountId, 3);
      expect(copy.toAccountId, 4);
      expect(copy.frequency, 'Annuel');
    });

    test('toJson should serialize all fields', () {
      final date = DateTime(2024, 3, 15);
      final transfer = TransferModel.create(
        name: 'Loyer coloc',
        amount: 450,
        fromAccountId: 1,
        toAccountId: 2,
        date: date,
        frequency: 'Mensuel',
      )..id = 10;

      final json = transfer.toJson();

      expect(json['id'], '10');
      expect(json['name'], 'Loyer coloc');
      expect(json['amount'], 450);
      expect(json['fromAccountId'], '1');
      expect(json['toAccountId'], '2');
      expect(json['date'], date.toIso8601String());
      expect(json['frequency'], 'Mensuel');
    });

    test('fromJson should deserialize all fields', () {
      final json = {
        'id': '5',
        'name': 'Épargne',
        'amount': 200.0,
        'fromAccountId': '1',
        'toAccountId': '3',
        'date': '2024-06-01T00:00:00.000',
        'frequency': 'Mensuel',
      };

      final transfer = TransferModel.fromJson(json);

      expect(transfer.id, 5);
      expect(transfer.name, 'Épargne');
      expect(transfer.amount, 200.0);
      expect(transfer.fromAccountId, 1);
      expect(transfer.toAccountId, 3);
      expect(transfer.date, DateTime(2024, 6, 1));
      expect(transfer.frequency, 'Mensuel');
    });

    test('fromJson should handle missing fields with defaults', () {
      final json = <String, dynamic>{};

      final transfer = TransferModel.fromJson(json);

      expect(transfer.id, 0);
      expect(transfer.name, '');
      expect(transfer.amount, 0.0);
      expect(transfer.fromAccountId, 0);
      expect(transfer.toAccountId, 0);
      expect(transfer.frequency, '');
    });

    test('toJson then fromJson should produce equivalent model', () {
      final date = DateTime(2024, 9, 20);
      final original = TransferModel.create(
        name: 'Roundtrip',
        amount: 750,
        fromAccountId: 2,
        toAccountId: 5,
        date: date,
        frequency: 'Annuel',
      )..id = 42;

      final restored = TransferModel.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.amount, original.amount);
      expect(restored.fromAccountId, original.fromAccountId);
      expect(restored.toAccountId, original.toAccountId);
      expect(restored.frequency, original.frequency);
    });
  });
}
