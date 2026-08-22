import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/entities/loan_event.dart';
import 'package:mybudget/core/entities/loan_installment.dart';
import 'package:mybudget/core/entities/loan_schedule.dart';
import 'package:mybudget/core/entities/loan_terms.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_event_types.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/core/services/early_repayment_indemnity_service.dart';
import 'package:mybudget/core/services/loan_schedule_service.dart';

void main() {
  const service = LoanScheduleService(EarlyRepaymentIndemnityService());

  LoanTerms termsOf({
    double amount = 10000,
    double rate = 5,
    int duration = 12,
    bool immediateFirstPayment = false,
    LoanRepaymentType repaymentType = LoanRepaymentType.amortizable,
    int deferredMonths = 0,
    LoanDeferralType deferralType = LoanDeferralType.none,
    LoanInsuranceType insuranceType = LoanInsuranceType.none,
    double insuranceValue = 0,
    InsuranceCalculationMode insuranceMode =
        InsuranceCalculationMode.initialCapital,
    double fees = 0,
    int dayOfMonth = 5,
    DateTime? startDate,
  }) {
    return LoanTerms(
      amount: amount,
      annualInterestRate: rate,
      durationInMonths: duration,
      startDate: startDate ?? DateTime(2026, 1, 5),
      dayOfMonth: dayOfMonth,
      immediateFirstPayment: immediateFirstPayment,
      repaymentType: repaymentType,
      deferredMonths: deferredMonths,
      deferralType: deferralType,
      insuranceType: insuranceType,
      insuranceValue: insuranceValue,
      insuranceCalculationMode: insuranceMode,
      fees: fees,
    );
  }

  void expectFullyRepaid(LoanSchedule schedule) {
    final repaid = schedule.installments.fold(
      0.0,
      (sum, i) => sum + i.principal + i.earlyPrincipal,
    );
    expect(repaid, closeTo(schedule.borrowedAmount, 0.001));
    expect(schedule.installments.last.closingCapital, closeTo(0, 0.001));
  }

  group('amortizable schedule', () {
    test('produces one installment per contractual month', () {
      final schedule = service.build(termsOf());

      expect(schedule.installmentCount, 12);
    });

    test('keeps the payment constant across installments', () {
      final schedule = service.build(termsOf());

      final payments = schedule.installments
          .take(11)
          .map((i) => i.scheduledPayment)
          .toSet();

      expect(payments, {856.07});
    });

    test('repays exactly the borrowed capital', () {
      expectFullyRepaid(service.build(termsOf()));
    });

    test('adjusts the last installment to absorb rounding', () {
      final schedule = service.build(termsOf());
      final last = schedule.installments.last;

      expect(last.principal, closeTo(last.openingCapital, 0.001));
      expect(last.scheduledPayment, closeTo(856.07, 1));
      expect(last.closingCapital, closeTo(0, 0.001));
    });

    test('charges decreasing interest as the capital amortizes', () {
      final schedule = service.build(termsOf());

      expect(schedule.installments.first.interest, closeTo(41.67, 0.01));
      expect(
        schedule.installments.last.interest,
        lessThan(schedule.installments.first.interest),
      );
      expect(schedule.totalInterest, closeTo(272.9, 0.5));
    });

    test('handles a zero rate instalment plan', () {
      final schedule = service.build(
        termsOf(
          amount: 1000,
          rate: 0,
          duration: 4,
          immediateFirstPayment: true,
          dayOfMonth: 15,
          startDate: DateTime(2026, 1, 15),
        ),
      );

      expect(schedule.installmentCount, 4);
      expect(schedule.totalInterest, 0);
      expect(
        schedule.installments.map((i) => i.scheduledPayment),
        everyElement(250.0),
      );
      expectFullyRepaid(schedule);
    });
  });

  group('installment dates', () {
    test('starts one month after the start date by default', () {
      final schedule = service.build(termsOf());

      expect(schedule.installments.first.date, DateTime(2026, 2, 5));
      expect(schedule.endDate, DateTime(2027, 1, 5));
    });

    test('bills the first installment on the start date when immediate', () {
      final schedule = service.build(
        termsOf(immediateFirstPayment: true),
      );

      expect(schedule.installments.first.date, DateTime(2026, 1, 5));
      expect(schedule.endDate, DateTime(2026, 12, 5));
    });

    test('clamps the billing day to the length of the month', () {
      final schedule = service.build(
        termsOf(dayOfMonth: 31, startDate: DateTime(2026, 1, 31)),
      );

      expect(schedule.installments.first.date, DateTime(2026, 2, 28));
      expect(schedule.installments[1].date, DateTime(2026, 3, 31));
    });
  });

  group('in fine schedule', () {
    test('bills interest only until the final capital repayment', () {
      final schedule = service.build(
        termsOf(rate: 6, repaymentType: LoanRepaymentType.inFine),
      );

      expect(schedule.installments.first.interest, closeTo(50, 0.01));
      expect(schedule.installments.first.principal, 0);
      expect(schedule.installments.last.principal, closeTo(10000, 0.01));
      expect(schedule.totalInterest, closeTo(600, 0.01));
      expectFullyRepaid(schedule);
    });

    test('keeps the capital outstanding until the end', () {
      final schedule = service.build(
        termsOf(rate: 6, repaymentType: LoanRepaymentType.inFine),
      );

      expect(schedule.installments[10].closingCapital, closeTo(10000, 0.01));
    });
  });

  group('partial deferral', () {
    test('bills interest without amortizing the capital', () {
      final schedule = service.build(
        termsOf(
          rate: 12,
          deferredMonths: 3,
          deferralType: LoanDeferralType.partial,
        ),
      );

      final deferred = schedule.installments.take(3);

      expect(deferred, everyElement(isA<LoanInstallment>()));
      expect(deferred.map((i) => i.interest), everyElement(closeTo(100, 0.01)));
      expect(deferred.map((i) => i.principal), everyElement(0));
      expect(deferred.last.closingCapital, closeTo(10000, 0.01));
    });

    test('amortizes over the remaining months once the deferral ends', () {
      final schedule = service.build(
        termsOf(
          rate: 12,
          deferredMonths: 3,
          deferralType: LoanDeferralType.partial,
        ),
      );

      expect(schedule.installmentCount, 12);
      expect(schedule.installments[3].scheduledPayment, closeTo(1167.4, 0.05));
      expectFullyRepaid(schedule);
    });
  });

  group('total deferral', () {
    test('capitalizes the unpaid interest into the capital', () {
      final schedule = service.build(
        termsOf(
          rate: 12,
          deferredMonths: 3,
          deferralType: LoanDeferralType.total,
        ),
      );

      expect(schedule.installments.first.scheduledPayment, 0);
      expect(schedule.installments[2].closingCapital, closeTo(10303.01, 0.01));
    });

    test('recomputes the payment on the increased capital', () {
      final schedule = service.build(
        termsOf(
          rate: 12,
          deferredMonths: 3,
          deferralType: LoanDeferralType.total,
        ),
      );

      expect(schedule.installments[3].scheduledPayment, closeTo(1202.78, 0.05));
      expectFullyRepaid(schedule);
    });

    test('still bills the insurance during the deferral', () {
      final schedule = service.build(
        termsOf(
          rate: 12,
          deferredMonths: 3,
          deferralType: LoanDeferralType.total,
          insuranceType: LoanInsuranceType.fixed,
          insuranceValue: 20,
        ),
      );

      expect(schedule.installments.first.scheduledPayment, 20);
      expect(schedule.installments.first.insurance, 20);
    });
  });

  group('insurance', () {
    test('bills a flat premium every month', () {
      final schedule = service.build(
        termsOf(insuranceType: LoanInsuranceType.fixed, insuranceValue: 20),
      );

      expect(schedule.installments.map((i) => i.insurance), everyElement(20.0));
      expect(schedule.totalInsurance, closeTo(240, 0.01));
    });

    test('bills a constant premium on the initial capital', () {
      final schedule = service.build(
        termsOf(
          insuranceType: LoanInsuranceType.percentage,
          insuranceValue: 0.36,
        ),
      );

      expect(schedule.installments.map((i) => i.insurance), everyElement(3.0));
    });

    test('bills a decreasing premium on the remaining capital', () {
      final schedule = service.build(
        termsOf(
          insuranceType: LoanInsuranceType.percentage,
          insuranceValue: 0.36,
          insuranceMode: InsuranceCalculationMode.remainingCapital,
        ),
      );

      expect(schedule.installments.first.insurance, closeTo(3.0, 0.01));
      expect(
        schedule.installments.last.insurance,
        lessThan(schedule.installments.first.insurance),
      );
      expect(schedule.totalInsurance, lessThan(36));
    });
  });

  group('total early repayment', () {
    test('settles the outstanding capital at the next installment', () {
      final schedule = service.build(
        termsOf(amount: 12000, rate: 0, duration: 12),
        events: [
          LoanEvent(
            type: LoanEventType.earlyRepaymentTotal,
            date: DateTime(2026, 7, 5),
          ),
        ],
      );

      final settlement = schedule.installments.last;

      expect(schedule.installmentCount, 6);
      expect(settlement.date, DateTime(2026, 7, 5));
      expect(settlement.principal, closeTo(1000, 0.01));
      expect(settlement.earlyPrincipal, closeTo(6000, 0.01));
      expect(settlement.closingCapital, closeTo(0, 0.001));
      expectFullyRepaid(schedule);
    });

    test('settles at the first installment following the requested date', () {
      final schedule = service.build(
        termsOf(amount: 12000, rate: 0, duration: 12),
        events: [
          LoanEvent(
            type: LoanEventType.earlyRepaymentTotal,
            date: DateTime(2026, 7, 20),
          ),
        ],
      );

      expect(schedule.installments.last.date, DateTime(2026, 8, 5));
      expect(schedule.installmentCount, 7);
    });

    test('drops the interest of the cancelled installments', () {
      final baseline = service.build(termsOf(rate: 5, duration: 12));
      final settled = service.build(
        termsOf(rate: 5, duration: 12),
        events: [
          LoanEvent(
            type: LoanEventType.earlyRepaymentTotal,
            date: DateTime(2026, 7, 5),
          ),
        ],
      );

      expect(settled.totalInterest, lessThan(baseline.totalInterest));
      expectFullyRepaid(settled);
    });

    test('charges the legal indemnity on the settlement installment', () {
      final schedule = service.build(
        termsOf(amount: 200000, rate: 3, duration: 240),
        events: [
          LoanEvent(
            type: LoanEventType.earlyRepaymentTotal,
            date: DateTime(2026, 7, 5),
          ),
        ],
      );

      final settlement = schedule.installments.last;

      expect(settlement.indemnity, greaterThan(0));
      expect(
        settlement.indemnity,
        closeTo(settlement.earlyPrincipal * 0.03 / 2, 0.5),
      );
    });

    test('waives the indemnity for a legal exemption', () {
      final schedule = service.build(
        termsOf(amount: 200000, rate: 3, duration: 240),
        events: [
          LoanEvent(
            type: LoanEventType.earlyRepaymentTotal,
            date: DateTime(2026, 7, 5),
            exemption: EarlyRepaymentExemption.death,
          ),
        ],
      );

      expect(schedule.installments.last.indemnity, 0);
    });
  });

  group('partial early repayment', () {
    test('shortens the schedule when reducing the duration', () {
      final schedule = service.build(
        termsOf(amount: 12000, rate: 0, duration: 12),
        events: [
          LoanEvent(
            type: LoanEventType.earlyRepaymentPartial,
            date: DateTime(2026, 7, 5),
            amount: 2000,
          ),
        ],
      );

      expect(schedule.installmentCount, 10);
      expect(schedule.installments[6].scheduledPayment, closeTo(1000, 0.01));
      expectFullyRepaid(schedule);
    });

    test('lowers the payment when keeping the duration', () {
      final schedule = service.build(
        termsOf(amount: 12000, rate: 0, duration: 12),
        events: [
          LoanEvent(
            type: LoanEventType.earlyRepaymentPartial,
            date: DateTime(2026, 7, 5),
            amount: 2000,
            reamortizationMode: ReamortizationMode.reducePayment,
          ),
        ],
      );

      expect(schedule.installmentCount, 12);
      expect(schedule.installments[6].scheduledPayment, closeTo(666.67, 0.01));
      expectFullyRepaid(schedule);
    });

    test('caps a partial repayment at the outstanding capital', () {
      final schedule = service.build(
        termsOf(amount: 12000, rate: 0, duration: 12),
        events: [
          LoanEvent(
            type: LoanEventType.earlyRepaymentPartial,
            date: DateTime(2026, 7, 5),
            amount: 99000,
          ),
        ],
      );

      expect(schedule.installments.last.date, DateTime(2026, 7, 5));
      expectFullyRepaid(schedule);
    });

    test('applies several repayments in chronological order', () {
      final schedule = service.build(
        termsOf(amount: 12000, rate: 0, duration: 12),
        events: [
          LoanEvent(
            type: LoanEventType.earlyRepaymentPartial,
            date: DateTime(2026, 9, 5),
            amount: 1000,
          ),
          LoanEvent(
            type: LoanEventType.earlyRepaymentPartial,
            date: DateTime(2026, 7, 5),
            amount: 2000,
          ),
        ],
      );

      expect(
        schedule.installments.where((i) => i.hasEarlyRepayment).length,
        2,
      );
      expectFullyRepaid(schedule);
    });

    test('ignores a repayment dated after the end of the loan', () {
      final baseline = service.build(termsOf(amount: 12000, rate: 0));
      final schedule = service.build(
        termsOf(amount: 12000, rate: 0),
        events: [
          LoanEvent(
            type: LoanEventType.earlyRepaymentPartial,
            date: DateTime(2030, 1, 5),
            amount: 2000,
          ),
        ],
      );

      expect(schedule.installmentCount, baseline.installmentCount);
      expectFullyRepaid(schedule);
    });
  });

  group('contract guards', () {
    test('always leaves one installment to repay the capital', () {
      for (final type in [LoanDeferralType.partial, LoanDeferralType.total]) {
        final schedule = service.build(
          termsOf(rate: 12, deferredMonths: 12, deferralType: type),
        );

        expect(schedule.installmentCount, 12, reason: '$type');
        expectFullyRepaid(schedule);
        expect(schedule.isCompletedAt(DateTime(2030, 1, 1)), isTrue);
      }
    });

    test('leaves the in fine capital repayable despite a full deferral', () {
      final schedule = service.build(
        termsOf(
          rate: 6,
          repaymentType: LoanRepaymentType.inFine,
          deferredMonths: 12,
          deferralType: LoanDeferralType.partial,
        ),
      );

      expectFullyRepaid(schedule);
    });

    test('caps the schedule at the maximum supported duration', () {
      final schedule = service.build(termsOf(rate: 3, duration: 100000));

      expect(schedule.installmentCount, LoanTerms.maxDurationInMonths);
      expectFullyRepaid(schedule);
    });

    test('treats a negative rate as a zero rate', () {
      final schedule = service.build(termsOf(rate: -2, duration: 12));

      expect(schedule.totalInterest, 0);
      expect(
        schedule.installments.take(11).map((i) => i.scheduledPayment),
        everyElement(closeTo(833.33, 0.01)),
      );
      expectFullyRepaid(schedule);
    });
  });

  group('upfront first installment', () {
    test('charges no interest on the day the funds are released', () {
      final schedule = service.build(
        termsOf(
          amount: 3000,
          rate: 19.9,
          duration: 4,
          immediateFirstPayment: true,
          dayOfMonth: 15,
          startDate: DateTime(2026, 1, 15),
        ),
      );

      expect(schedule.installments.first.interest, 0);
      expect(schedule.installments.first.scheduledPayment, closeTo(768.64, 0.05));
      expect(schedule.totalInterest, closeTo(74.41, 0.1));
      expectFullyRepaid(schedule);
    });

    test('costs less than the same loan billed a month later', () {
      LoanTerms termsFor({required bool immediate}) => LoanTerms(
        amount: 3000,
        annualInterestRate: 19.9,
        durationInMonths: 4,
        startDate: DateTime(2026, 1, 15),
        dayOfMonth: 15,
        immediateFirstPayment: immediate,
      );

      expect(
        service.build(termsFor(immediate: true)).totalInterest,
        lessThan(service.build(termsFor(immediate: false)).totalInterest),
      );
    });
  });

  group('consumer indemnity cap during a deferral', () {
    test('caps at the interest the contract would still have charged', () {
      final terms = termsOf(
        amount: 60000,
        rate: 0.1,
        duration: 60,
        deferredMonths: 48,
        deferralType: LoanDeferralType.total,
      );
      final contractual = service.build(terms);
      final settled = service.build(
        terms,
        events: [
          LoanEvent(
            type: LoanEventType.earlyRepaymentPartial,
            date: DateTime(2026, 6, 5),
            amount: 30000,
          ),
        ],
      );

      final settlement = settled.installments.firstWhere(
        (i) => i.hasEarlyRepayment,
      );
      final futureContractualInterest = contractual.installments
          .where((i) => i.number > settlement.number)
          .fold(0.0, (sum, i) => sum + i.interest);

      expect(
        settlement.indemnity,
        lessThanOrEqualTo(futureContractualInterest + 0.01),
      );
    });
  });

  group('determinism', () {
    test('returns identical schedules for identical inputs', () {
      final first = service.build(termsOf(rate: 3.7, duration: 84));
      final second = service.build(termsOf(rate: 3.7, duration: 84));

      expect(
        first.installments.map((i) => i.totalPayment),
        second.installments.map((i) => i.totalPayment),
      );
    });
  });

  group('degenerate contracts', () {
    test('returns an empty schedule for a zero duration', () {
      expect(service.build(termsOf(duration: 0)).isEmpty, isTrue);
    });

    test('returns an empty schedule for a zero amount', () {
      expect(service.build(termsOf(amount: 0)).isEmpty, isTrue);
    });

    test('handles a single installment loan', () {
      final schedule = service.build(termsOf(amount: 500, rate: 0, duration: 1));

      expect(schedule.installmentCount, 1);
      expect(schedule.installments.single.scheduledPayment, 500);
    });
  });
}
