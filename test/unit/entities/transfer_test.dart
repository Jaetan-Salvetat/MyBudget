import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/entities/transfer.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/models/transfer_model.dart';

void main() {
  group('Transfer entity', () {
    TransferModel makeModel({
      String name = 'Test',
      double amount = 600,
      int fromAccountId = 1,
      int toAccountId = 2,
      Frequency frequency = Frequency.monthly,
    }) {
      return TransferModel.create(
        name: name,
        amount: amount,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        startDate: DateTime(2024, 6, 15),
        frequency: frequency,
      );
    }

    test('exposes all model fields', () {
      final model = makeModel(name: 'Épargne', amount: 300)..id = 5;
      final transfer = Transfer.fromModel(model);

      expect(transfer.id, 5);
      expect(transfer.name, 'Épargne');
      expect(transfer.amount, 300);
      expect(transfer.fromAccountId, 1);
      expect(transfer.toAccountId, 2);
      expect(transfer.startDate, DateTime(2024, 6, 15));
    });

    test('model getter returns underlying model', () {
      final model = makeModel();
      final transfer = Transfer(model);

      expect(identical(transfer.model, model), isTrue);
    });

    test('monthlyAmount returns amount directly for monthly frequency', () {
      final transfer = Transfer.fromModel(
        makeModel(amount: 500, frequency: Frequency.monthly),
      );

      expect(transfer.monthlyAmount, 500);
    });

    test('monthlyAmount divides by 12 for annual frequency', () {
      final transfer = Transfer.fromModel(
        makeModel(amount: 1200, frequency: Frequency.annual),
      );

      expect(transfer.monthlyAmount, 100);
    });

    test('monthlyAmount returns 0 for oneTime frequency', () {
      final transfer = Transfer.fromModel(
        makeModel(amount: 500, frequency: Frequency.oneTime),
      );

      expect(transfer.monthlyAmount, 0);
    });

    test('isOutgoingFrom returns true when account is source', () {
      final transfer = Transfer.fromModel(
        makeModel(fromAccountId: 3, toAccountId: 5),
      );

      expect(transfer.isOutgoingFrom(3), isTrue);
      expect(transfer.isOutgoingFrom(5), isFalse);
      expect(transfer.isOutgoingFrom(99), isFalse);
    });

    test('isIncomingTo returns true when account is destination', () {
      final transfer = Transfer.fromModel(
        makeModel(fromAccountId: 3, toAccountId: 5),
      );

      expect(transfer.isIncomingTo(5), isTrue);
      expect(transfer.isIncomingTo(3), isFalse);
      expect(transfer.isIncomingTo(99), isFalse);
    });

    test('fromModel factory creates Transfer correctly', () {
      final model = makeModel(name: 'Factory test');
      final transfer = Transfer.fromModel(model);

      expect(transfer.name, 'Factory test');
    });
  });
}
