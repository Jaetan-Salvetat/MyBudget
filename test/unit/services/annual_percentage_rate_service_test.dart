import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/entities/loan_schedule.dart';
import 'package:mybudget/core/entities/loan_terms.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/services/annual_percentage_rate_service.dart';
import 'package:mybudget/core/services/early_repayment_indemnity_service.dart';
import 'package:mybudget/core/services/loan_schedule_service.dart';

void main() {
  const scheduleService = LoanScheduleService(EarlyRepaymentIndemnityService());
  const service = AnnualPercentageRateService();

  double aprOf(LoanTerms terms) {
    return service.compute(
      schedule: scheduleService.build(terms),
      originDate: terms.startDate,
    );
  }

  test('returns zero for a free instalment plan', () {
    final apr = aprOf(
      LoanTerms(
        amount: 1000,
        annualInterestRate: 0,
        durationInMonths: 4,
        startDate: DateTime(2026, 1, 15),
        dayOfMonth: 15,
        immediateFirstPayment: true,
      ),
    );

    expect(apr, 0);
  });

  test('matches the nominal rate when there is no other cost', () {
    final apr = aprOf(
      LoanTerms(
        amount: 10000,
        annualInterestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2026, 1, 5),
        dayOfMonth: 5,
      ),
    );

    expect(apr, closeTo(5.116, 0.02));
  });

  test('prices the arrangement fee of a free instalment plan', () {
    final apr = aprOf(
      LoanTerms(
        amount: 1000,
        annualInterestRate: 0,
        durationInMonths: 4,
        startDate: DateTime(2026, 1, 15),
        dayOfMonth: 15,
        immediateFirstPayment: true,
        fees: 5.95,
      ),
    );

    expect(apr, greaterThan(4));
  });

  test('rises above the nominal rate once fees are charged', () {
    final nominal = aprOf(
      LoanTerms(
        amount: 10000,
        annualInterestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2026, 1, 5),
        dayOfMonth: 5,
      ),
    );
    final withFees = aprOf(
      LoanTerms(
        amount: 10000,
        annualInterestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2026, 1, 5),
        dayOfMonth: 5,
        fees: 300,
      ),
    );

    expect(withFees, greaterThan(nominal));
  });

  test('rises above the nominal rate once insurance is charged', () {
    final withInsurance = aprOf(
      LoanTerms(
        amount: 10000,
        annualInterestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2026, 1, 5),
        dayOfMonth: 5,
        insuranceType: LoanInsuranceType.fixed,
        insuranceValue: 15,
      ),
    );

    expect(withInsurance, greaterThan(8));
  });

  test('returns zero for an empty schedule', () {
    final apr = service.compute(
      schedule: const LoanSchedule(installments: [], borrowedAmount: 0),
      originDate: DateTime(2026, 1, 1),
    );

    expect(apr, 0);
  });
}
