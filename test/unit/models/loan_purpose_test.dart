import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/models/loan_model.dart';

void main() {
  LoanModel modelOf({
    required LoanPurpose purpose,
    double amount = 20000,
  }) {
    return LoanModel.create(
      name: 'Prêt',
      amount: amount,
      lenderName: 'Banque',
      accountId: 1,
      dayOfMonth: 5,
      startDate: DateTime(2026, 1, 5),
      endDate: DateTime(2027, 1, 5),
      interestRate: 3,
      duration: 12,
      purpose: purpose,
    );
  }

  group('regime derivation', () {
    const consumerPurposes = [
      LoanPurpose.car,
      LoanPurpose.personal,
      LoanPurpose.student,
      LoanPurpose.instalmentPlan,
    ];

    for (final purpose in consumerPurposes) {
      test('maps ${purpose.name} to the consumer regime', () {
        expect(
          modelOf(purpose: purpose, amount: 500000).regime,
          CreditRegime.consumer,
        );
      });
    }

    for (final purpose in [LoanPurpose.mortgage, LoanPurpose.bridge]) {
      test('maps ${purpose.name} to the mortgage regime', () {
        expect(
          modelOf(purpose: purpose, amount: 1000).regime,
          CreditRegime.mortgage,
        );
      });
    }

    const amountDrivenPurposes = [
      LoanPurpose.works,
      LoanPurpose.family,
      LoanPurpose.other,
    ];

    for (final purpose in amountDrivenPurposes) {
      test('derives ${purpose.name} from the legal threshold', () {
        expect(
          modelOf(purpose: purpose, amount: 70000).regime,
          CreditRegime.consumer,
        );
        expect(
          modelOf(purpose: purpose, amount: 80000).regime,
          CreditRegime.mortgage,
        );
      });
    }

    test('follows the amount when the contract is corrected', () {
      final model = modelOf(purpose: LoanPurpose.works, amount: 70000);
      expect(model.regime, CreditRegime.consumer);

      model.amount = 80000;
      expect(model.regime, CreditRegime.mortgage);
    });
  });

  group('persistence', () {
    test('stores the purpose and never the derived regime', () {
      final json = modelOf(purpose: LoanPurpose.car).toJson();

      expect(json['purposeId'], 'car');
      expect(json.containsKey('regimeId'), isFalse);
      expect(LoanModel.fromJson(json).purpose, LoanPurpose.car);
    });

    test('falls back to the neutral purpose for an unknown value', () {
      final model = modelOf(purpose: LoanPurpose.car)..purposeId = 'leasing';

      expect(model.purpose, LoanPurpose.other);
      expect(model.regime, CreditRegime.consumer);
    });

    test('falls back to the neutral purpose for a legacy record', () {
      final json = modelOf(purpose: LoanPurpose.car).toJson()
        ..remove('purposeId');

      expect(LoanModel.fromJson(json).purpose, LoanPurpose.other);
    });
  });

  group('default waivers', () {
    test('waives the indemnity for private and bridge loans', () {
      expect(LoanPurpose.family.waivesIndemnityByDefault, isTrue);
      expect(LoanPurpose.bridge.waivesIndemnityByDefault, isTrue);
    });

    test('keeps the indemnity for every bank product', () {
      for (final purpose in [
        LoanPurpose.mortgage,
        LoanPurpose.works,
        LoanPurpose.car,
        LoanPurpose.personal,
        LoanPurpose.student,
        LoanPurpose.instalmentPlan,
        LoanPurpose.other,
      ]) {
        expect(
          purpose.waivesIndemnityByDefault,
          isFalse,
          reason: purpose.name,
        );
      }
    });
  });
}
