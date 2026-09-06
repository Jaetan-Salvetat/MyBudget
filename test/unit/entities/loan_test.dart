import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_event_types.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/models/loan_event_model.dart';
import 'package:mybudget/models/loan_model.dart';

import '../../helpers/loan_test_factory.dart';

void main() {
  LoanModel modelOf({
    double amount = 12000,
    double rate = 0,
    int duration = 12,
    LoanInsuranceType insuranceType = LoanInsuranceType.none,
    double insuranceValue = 0,
  }) {
    return LoanModel.create(
      name: 'Prêt',
      amount: amount,
      lenderName: 'Banque',
      accountId: 1,
      dayOfMonth: 5,
      startDate: DateTime(2026, 1, 5),
      endDate: DateTime(2027, 1, 5),
      interestRate: rate,
      duration: duration,
      insuranceType: insuranceType,
      insuranceValue: insuranceValue,
    );
  }

  group('lifecycle', () {
    test('is pending before the first installment', () {
      final loan = buildTestLoan(modelOf(), asOf: DateTime(2026, 1, 1));

      expect(loan.isPending, isTrue);
      expect(loan.isActive, isFalse);
      expect(loan.getStatus(), LoanStatus.pending);
      expect(loan.remainingCapital, 12000);
      expect(loan.paidMonths, 0);
      expect(loan.progressPercentage, 0);
    });

    test('is active midway through the schedule', () {
      final loan = buildTestLoan(modelOf(), asOf: DateTime(2026, 7, 5));

      expect(loan.isActive, isTrue);
      expect(loan.getStatus(), LoanStatus.partiallyPaid);
      expect(loan.paidMonths, 6);
      expect(loan.remainingCapital, closeTo(6000, 0.01));
      expect(loan.remainingMonths, 6);
      expect(loan.progressPercentage, closeTo(0.5, 0.001));
      expect(loan.currentMonthlyPayment, closeTo(1000, 0.01));
    });

    test('is completed once the last installment is settled', () {
      final loan = buildTestLoan(modelOf(), asOf: DateTime(2027, 2, 1));

      expect(loan.isCompleted, isTrue);
      expect(loan.getStatus(), LoanStatus.completed);
      expect(loan.remainingCapital, closeTo(0, 0.01));
      expect(loan.remainingMonths, 0);
      expect(loan.currentMonthlyPayment, 0);
      expect(loan.progressPercentage, 1);
    });

    test('derives the end date from the schedule', () {
      final loan = buildTestLoan(modelOf(), asOf: DateTime(2026, 7, 5));

      expect(loan.endDate, DateTime(2027, 1, 5));
    });
  });

  group('degenerate contracts', () {
    test('never reports an empty contract as repaid', () {
      final loan = buildTestLoan(
        modelOf(amount: 0),
        asOf: DateTime(2026, 7, 5),
      );

      expect(loan.isCompleted, isFalse);
      expect(loan.getStatus(), LoanStatus.partiallyPaid);
      expect(loan.endDate, loan.startDate);
    });

    test('stays unpaid when the deferral swallows the whole duration', () {
      final model = modelOf(rate: 12)
        ..deferredMonths = 12
        ..deferralType = LoanDeferralType.partial;
      final loan = buildTestLoan(model, asOf: DateTime(2030, 1, 1));

      expect(loan.remainingCapital, closeTo(0, 0.01));
      expect(loan.isCompleted, isTrue);
      expect(
        loan.cumulativePaymentBreakdown.capitalPayment,
        closeTo(loan.amount, 0.01),
      );
    });
  });

  group('cumulative amounts', () {
    test('counts the same months as the remaining capital', () {
      for (final asOf in [
        DateTime(2026, 3, 4),
        DateTime(2026, 3, 5),
        DateTime(2026, 3, 6),
        DateTime(2026, 11, 20),
      ]) {
        final loan = buildTestLoan(modelOf(), asOf: asOf);
        final repaid = loan.amount - loan.remainingCapital;

        expect(
          loan.cumulativePaymentBreakdown.capitalPayment,
          closeTo(repaid, 0.01),
          reason: 'mismatch at $asOf',
        );
      }
    });

    test('splits the cumulative payment into its components', () {
      final loan = buildTestLoan(
        modelOf(
          rate: 5,
          insuranceType: LoanInsuranceType.fixed,
          insuranceValue: 10,
        ),
        asOf: DateTime(2026, 7, 5),
      );
      final breakdown = loan.cumulativePaymentBreakdown;

      expect(
        breakdown.capitalPayment +
            breakdown.interestPayment +
            breakdown.insurancePayment,
        closeTo(breakdown.totalPayment, 0.01),
      );
      expect(breakdown.insurancePayment, closeTo(60, 0.01));
      expect(loan.totalPaidAmount, closeTo(breakdown.totalPayment, 0.01));
    });

    test('keeps the contractual cost stable over time', () {
      final early = buildTestLoan(modelOf(rate: 5), asOf: DateTime(2026, 2, 5));
      final late = buildTestLoan(modelOf(rate: 5), asOf: DateTime(2026, 12, 5));

      expect(early.totalCost, closeTo(late.totalCost, 0.01));
      expect(early.totalCost, greaterThan(0));
    });
  });

  group('early repayment', () {
    LoanEventModel payoffAt(DateTime date) => LoanEventModel.create(
      loanId: 1,
      type: LoanEventType.earlyRepaymentTotal,
      date: date,
    );

    test('reports the savings against the contractual schedule', () {
      final model = modelOf(rate: 5)..id = 1;
      final loan = buildTestLoan(
        model,
        asOf: DateTime(2026, 7, 5),
        events: [payoffAt(DateTime(2026, 7, 5))],
      );

      expect(loan.hasEarlyRepayment, isTrue);
      expect(loan.monthsSaved, 6);
      expect(loan.costSaved, greaterThan(0));
      expect(loan.totalCost, lessThan(loan.contractualCost));
      expect(loan.isCompleted, isTrue);
    });

    test('keeps the contractual TAEG after an early repayment', () {
      final model = modelOf(rate: 5)..id = 1;
      final contractual = buildTestLoan(model, asOf: DateTime(2026, 7, 5));
      final settled = buildTestLoan(
        model,
        asOf: DateTime(2026, 7, 5),
        events: [payoffAt(DateTime(2026, 7, 5))],
      );

      expect(settled.annualPercentageRate, contractual.annualPercentageRate);
    });

    test('reports no savings when there is no event', () {
      final loan = buildTestLoan(modelOf(rate: 5), asOf: DateTime(2026, 7, 5));

      expect(loan.hasEarlyRepayment, isFalse);
      expect(loan.costSaved, 0);
      expect(loan.monthsSaved, 0);
    });
  });
}
