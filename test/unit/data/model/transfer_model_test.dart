import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/data/model/transfer_model.dart';

final DateTime _fixedNow = DateTime(2026, 6, 15, 9, 30);

void main() {
  group('TransferModel', () {
    test('should map Frequency enum to string correctly', () {
      final transfer = TransferModel.create(
        name: 'Virement test',
        amount: 500,
        fromAccountId: 1,
        toAccountId: 2,
        startDate: DateTime.now(),
        frequency: Frequency.monthly,
      );

      expect(transfer.frequencyEnum, Frequency.monthly);

      transfer.frequencyEnum = Frequency.annual;
      expect(transfer.frequency, Frequency.annual.storageKey);
    });

    test('copyWith should preserve other fields', () {
      final original = TransferModel.create(
        name: 'Original',
        amount: 300,
        fromAccountId: 1,
        toAccountId: 2,
        startDate: DateTime(2024, 6, 15),
        frequency: Frequency.monthly,
      )..id = 7;

      final copy = original.copyWith(name: 'Modifié');

      expect(copy.id, 7);
      expect(copy.name, 'Modifié');
      expect(copy.amount, 300);
      expect(copy.fromAccountId, 1);
      expect(copy.toAccountId, 2);
      expect(copy.frequency, Frequency.monthly.storageKey);
    });

    test('copyWith should override specified fields', () {
      final original = TransferModel.create(
        name: 'Original',
        amount: 300,
        fromAccountId: 1,
        toAccountId: 2,
        startDate: DateTime(2024, 6, 15),
        frequency: Frequency.monthly,
      );

      final copy = original.copyWith(
        amount: 600,
        fromAccountId: 3,
        toAccountId: 4,
        frequency: Frequency.annual,
      );

      expect(copy.name, 'Original');
      expect(copy.amount, 600);
      expect(copy.fromAccountId, 3);
      expect(copy.toAccountId, 4);
      expect(copy.frequency, Frequency.annual.storageKey);
    });

    test('toJson should serialize all fields', () {
      final date = DateTime(2024, 3, 15);
      final transfer = TransferModel.create(
        name: 'Loyer coloc',
        amount: 450,
        fromAccountId: 1,
        toAccountId: 2,
        startDate: date,
        frequency: Frequency.monthly,
      )..id = 10;

      final json = transfer.toJson();

      expect(json['id'], '10');
      expect(json['name'], 'Loyer coloc');
      expect(json['amount'], 450);
      expect(json['fromAccountId'], '1');
      expect(json['toAccountId'], '2');
      expect(json['startDate'], date.toIso8601String());
      expect(json['frequency'], Frequency.monthly.storageKey);
    });

    test('fromJson should deserialize all fields', () {
      final json = {
        'id': '5',
        'name': 'Épargne',
        'amount': 200.0,
        'fromAccountId': '1',
        'toAccountId': '3',
        'startDate': '2024-06-01T00:00:00.000',
        'frequency': 'Mensuel',
      };

      final transfer = TransferModel.fromJson(json, now: _fixedNow);

      expect(transfer.id, 5);
      expect(transfer.name, 'Épargne');
      expect(transfer.amount, 200.0);
      expect(transfer.fromAccountId, 1);
      expect(transfer.toAccountId, 3);
      expect(transfer.startDate, DateTime(2024, 6, 1));
      expect(transfer.frequency, Frequency.monthly.storageKey);
    });

    test('fromJson should handle missing fields with defaults', () {
      final json = <String, dynamic>{};

      final transfer = TransferModel.fromJson(json, now: _fixedNow);

      expect(transfer.id, 0);
      expect(transfer.name, '');
      expect(transfer.amount, 0.0);
      expect(transfer.fromAccountId, 0);
      expect(transfer.toAccountId, 0);
      expect(transfer.frequency, Frequency.monthly.storageKey);
    });

    test('toJson then fromJson should produce equivalent model', () {
      final date = DateTime(2024, 9, 20);
      final original = TransferModel.create(
        name: 'Roundtrip',
        amount: 750,
        fromAccountId: 2,
        toAccountId: 5,
        startDate: date,
        frequency: Frequency.annual,
      )..id = 42;

      final restored = TransferModel.fromJson(
        original.toJson(),
        now: _fixedNow,
      );

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.amount, original.amount);
      expect(restored.fromAccountId, original.fromAccountId);
      expect(restored.toAccountId, original.toAccountId);
      expect(restored.frequency, original.frequency);
    });

    test('copyWith with endDate and parentId using sentinel pattern', () {
      final original = TransferModel.create(
        name: 'Test',
        amount: 300,
        fromAccountId: 1,
        toAccountId: 2,
        startDate: DateTime(2024, 1, 1),
        frequency: Frequency.monthly,
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
      final transfer = TransferModel.create(
        name: 'Test',
        amount: 300,
        fromAccountId: 1,
        toAccountId: 2,
        startDate: DateTime(2024, 1, 1),
        frequency: Frequency.monthly,
        endDate: DateTime(2024, 6, 15),
        parentId: 3,
      )..id = 1;

      final json = transfer.toJson();

      expect(json['endDate'], DateTime(2024, 6, 15).toIso8601String());
      expect(json['parentId'], '3');
    });

    test('toJson with null endDate and parentId', () {
      final transfer = TransferModel.create(
        name: 'Test',
        amount: 300,
        fromAccountId: 1,
        toAccountId: 2,
        startDate: DateTime(2024, 1, 1),
        frequency: Frequency.monthly,
      );

      final json = transfer.toJson();

      expect(json['endDate'], isNull);
      expect(json['parentId'], isNull);
    });

    test('fromJson parses endDate and parentId', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'amount': 300.0,
        'fromAccountId': '1',
        'toAccountId': '2',
        'startDate': '2024-01-01T00:00:00.000',
        'endDate': '2024-06-15T00:00:00.000',
        'parentId': '3',
        'frequency': 'Mensuel',
      };

      final transfer = TransferModel.fromJson(json, now: _fixedNow);

      expect(transfer.endDate, DateTime(2024, 6, 15));
      expect(transfer.parentId, 3);
    });

    test('fromJson with null endDate and parentId', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'amount': 300.0,
        'fromAccountId': '1',
        'toAccountId': '2',
        'startDate': '2024-01-01T00:00:00.000',
        'frequency': 'Mensuel',
      };

      final transfer = TransferModel.fromJson(json, now: _fixedNow);

      expect(transfer.endDate, isNull);
      expect(transfer.parentId, isNull);
    });

    test('fromJson falls back on date key when startDate is missing', () {
      final json = {
        'id': '1',
        'name': 'Legacy',
        'amount': 300.0,
        'fromAccountId': '1',
        'toAccountId': '2',
        'date': '2024-03-20T00:00:00.000',
        'frequency': 'Mensuel',
      };

      final transfer = TransferModel.fromJson(json, now: _fixedNow);

      expect(transfer.startDate, DateTime(2024, 3, 20));
    });
  });

  group("la part mensuelle d'un virement", () {
    TransferModel virement({
      double amount = 600,
      int fromAccountId = 1,
      int toAccountId = 2,
      Frequency frequency = Frequency.monthly,
    }) {
      return TransferModel.create(
        name: 'Test',
        amount: amount,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        startDate: DateTime(2024, 6, 15),
        frequency: frequency,
      );
    }

    test('vaut le montant tel quel pour un virement mensuel', () {
      expect(virement(amount: 500).monthlyAmount, 500);
    });

    test('vaut le douzième du montant pour un virement annuel', () {
      expect(
        virement(amount: 1200, frequency: Frequency.annual).monthlyAmount,
        100,
      );
    });

    test('est nulle pour un virement ponctuel', () {
      expect(
        virement(amount: 500, frequency: Frequency.oneTime).monthlyAmount,
        0,
      );
    });

    test('sort du compte source et entre sur le compte cible', () {
      final transfer = virement(fromAccountId: 3, toAccountId: 5);

      expect(transfer.isOutgoingFrom(3), isTrue);
      expect(transfer.isOutgoingFrom(5), isFalse);
      expect(transfer.isIncomingTo(5), isTrue);
      expect(transfer.isIncomingTo(3), isFalse);
    });
  });
}
