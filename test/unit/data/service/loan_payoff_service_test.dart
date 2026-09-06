import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/loan_event_types.dart';
import 'package:mybudget/core/values/loan.dart';
import 'package:mybudget/core/values/loan_event.dart';
import 'package:mybudget/data/model/loan_event_model.dart';
import 'package:mybudget/data/model/loan_model.dart';

import '../../../helpers/loan_test_factory.dart';

void main() {
  Loan loanOf({double amount = 12000, double rate = 0, int duration = 12}) {
    final model = LoanModel.create(
      name: 'Prêt',
      amount: amount,
      lenderName: 'Banque',
      accountId: 1,
      dayOfMonth: 5,
      startDate: DateTime(2026, 1, 5),
      endDate: DateTime(2027, 1, 5),
      interestRate: rate,
      duration: duration,
    )..id = 1;

    return buildTestLoan(model, asOf: DateTime(2026, 7, 5));
  }

  group('total settlement', () {
    test('quotes the outstanding capital and the settlement installment', () {
      final quote = testPayoffService.quote(
        loan: loanOf(),
        event: LoanEvent(
          type: LoanEventType.earlyRepaymentTotal,
          date: DateTime(2026, 7, 5),
        ),
      )!;

      expect(quote.settlementDate, DateTime(2026, 7, 5));
      expect(quote.remainingCapitalBefore, closeTo(6000, 0.01));
      expect(quote.repaidCapital, closeTo(6000, 0.01));
      expect(quote.settlementPayment, closeTo(1000, 0.01));
      expect(quote.totalDue, closeTo(7000, 0.01));
      expect(quote.clearsTheLoan, isTrue);
      expect(quote.newEndDate, isNull);
      expect(quote.monthsSaved, 6);
    });

    test('quotes the legal indemnity on a mortgage', () {
      final quote = testPayoffService.quote(
        loan: loanOf(amount: 200000, rate: 3, duration: 240),
        event: LoanEvent(
          type: LoanEventType.earlyRepaymentTotal,
          date: DateTime(2026, 7, 5),
        ),
      )!;

      expect(quote.indemnity, greaterThan(0));
      expect(
        quote.totalDue,
        closeTo(
          quote.settlementPayment + quote.repaidCapital + quote.indemnity,
          0.01,
        ),
      );
      expect(quote.costSaved, greaterThan(0));
    });

    test('never flags a total settlement as below the bank minimum', () {
      final quote = testPayoffService.quote(
        loan: loanOf(),
        event: LoanEvent(
          type: LoanEventType.earlyRepaymentTotal,
          date: DateTime(2026, 12, 5),
        ),
      )!;

      expect(quote.isBelowBankMinimum, isFalse);
    });
  });

  group('partial settlement', () {
    test('shortens the loan while keeping the payment', () {
      final quote = testPayoffService.quote(
        loan: loanOf(),
        event: LoanEvent(
          type: LoanEventType.earlyRepaymentPartial,
          date: DateTime(2026, 7, 5),
          amount: 2000,
        ),
      )!;

      expect(quote.repaidCapital, closeTo(2000, 0.01));
      expect(quote.newMonthlyPayment, closeTo(1000, 0.01));
      expect(quote.monthsSaved, 2);
      expect(quote.newEndDate, DateTime(2026, 11, 5));
      expect(quote.clearsTheLoan, isFalse);
    });

    test('lowers the payment while keeping the duration', () {
      final quote = testPayoffService.quote(
        loan: loanOf(),
        event: LoanEvent(
          type: LoanEventType.earlyRepaymentPartial,
          date: DateTime(2026, 7, 5),
          amount: 2000,
          reamortizationMode: ReamortizationMode.reducePayment,
        ),
      )!;

      expect(quote.newMonthlyPayment, closeTo(666.67, 0.01));
      expect(quote.monthsSaved, 0);
      expect(quote.newEndDate, DateTime(2027, 1, 5));
    });

    test('flags a repayment below the ten percent bank minimum', () {
      final quote = testPayoffService.quote(
        loan: loanOf(),
        event: LoanEvent(
          type: LoanEventType.earlyRepaymentPartial,
          date: DateTime(2026, 7, 5),
          amount: 500,
        ),
      )!;

      expect(quote.isBelowBankMinimum, isTrue);
    });

    test('accepts a repayment at or above the bank minimum', () {
      final quote = testPayoffService.quote(
        loan: loanOf(),
        event: LoanEvent(
          type: LoanEventType.earlyRepaymentPartial,
          date: DateTime(2026, 7, 5),
          amount: 1200,
        ),
      )!;

      expect(quote.isBelowBankMinimum, isFalse);
    });
  });

  group('loans that already carry an event', () {
    Loan loanWithPriorRepayment() {
      final model = LoanModel.create(
        name: 'Prêt',
        amount: 200000,
        lenderName: 'Banque',
        accountId: 1,
        dayOfMonth: 5,
        startDate: DateTime(2026, 1, 5),
        endDate: DateTime(2046, 1, 5),
        interestRate: 3,
        duration: 240,
      )..id = 1;

      return buildTestLoan(
        model,
        asOf: DateTime(2027, 3, 1),
        events: [
          LoanEventModel.create(
            loanId: 1,
            type: LoanEventType.earlyRepaymentPartial,
            date: DateTime(2027, 3, 1),
            amount: 20000,
          ),
        ],
      );
    }

    test('quotes only the new repayment on a shared installment', () {
      final quote = testPayoffService.quote(
        loan: loanWithPriorRepayment(),
        event: LoanEvent(
          type: LoanEventType.earlyRepaymentPartial,
          date: DateTime(2027, 3, 3),
          amount: 10000,
        ),
      )!;

      expect(quote.settlementDate, DateTime(2027, 3, 5));
      expect(quote.repaidCapital, closeTo(10000, 0.01));
      expect(quote.indemnity, closeTo(150, 0.01));
      expect(quote.totalDue, closeTo(quote.settlementPayment + 10150, 0.01));
    });

    test('excludes the earlier repayment from the outstanding capital', () {
      final loan = loanWithPriorRepayment();
      final quote = testPayoffService.quote(
        loan: loan,
        event: LoanEvent(
          type: LoanEventType.earlyRepaymentPartial,
          date: DateTime(2027, 3, 3),
          amount: 10000,
        ),
      )!;

      expect(
        quote.remainingCapitalBefore,
        closeTo(loan.schedule.remainingCapitalAt(DateTime(2027, 3, 5)), 0.01),
      );
    });
  });

  group('invalid requests', () {
    test('returns no quote past the end of the loan', () {
      final quote = testPayoffService.quote(
        loan: loanOf(),
        event: LoanEvent(
          type: LoanEventType.earlyRepaymentTotal,
          date: DateTime(2030, 1, 5),
        ),
      );

      expect(quote, isNull);
    });

    test('returns no quote for a zero amount partial repayment', () {
      final quote = testPayoffService.quote(
        loan: loanOf(),
        event: LoanEvent(
          type: LoanEventType.earlyRepaymentPartial,
          date: DateTime(2026, 7, 5),
        ),
      );

      expect(quote, isNull);
    });
  });
}
