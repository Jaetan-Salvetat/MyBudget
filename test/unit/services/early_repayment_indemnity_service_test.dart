import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/entities/loan_terms.dart';
import 'package:mybudget/core/enums/loan_event_types.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/core/services/early_repayment_indemnity_service.dart';

void main() {
  const service = EarlyRepaymentIndemnityService();

  group('default regime', () {
    test('suggests the mortgage regime above the legal threshold', () {
      expect(LoanTerms.defaultRegimeFor(75000.01), CreditRegime.mortgage);
    });

    test('suggests the consumer regime at or below the threshold', () {
      expect(LoanTerms.defaultRegimeFor(75000), CreditRegime.consumer);
    });
  });

  group('mortgage regime', () {
    test('charges one semester of interest on the repaid capital', () {
      final result = service.compute(
        regime: CreditRegime.mortgage,
        repaidCapital: 50000,
        remainingCapitalBefore: 100000,
        annualInterestRate: 3,
        remainingMonths: 120,
        remainingInterest: 20000,
      );

      expect(result, closeTo(750, 0.01));
    });

    test('caps the indemnity at three percent of the remaining capital', () {
      final result = service.compute(
        regime: CreditRegime.mortgage,
        repaidCapital: 100000,
        remainingCapitalBefore: 100000,
        annualInterestRate: 10,
        remainingMonths: 120,
        remainingInterest: 50000,
      );

      expect(result, closeTo(3000, 0.01));
    });

    test('charges nothing on a zero rate loan', () {
      final result = service.compute(
        regime: CreditRegime.mortgage,
        repaidCapital: 100000,
        remainingCapitalBefore: 100000,
        annualInterestRate: 0,
        remainingMonths: 120,
        remainingInterest: 0,
      );

      expect(result, 0);
    });
  });

  group('consumer regime', () {
    test('charges nothing below the legal yearly threshold', () {
      final result = service.compute(
        regime: CreditRegime.consumer,
        repaidCapital: 5000,
        remainingCapitalBefore: 15000,
        annualInterestRate: 5,
        remainingMonths: 24,
        remainingInterest: 2000,
      );

      expect(result, 0);
    });

    test('counts repayments made over the last twelve months', () {
      final result = service.compute(
        regime: CreditRegime.consumer,
        repaidCapital: 3000,
        remainingCapitalBefore: 15000,
        annualInterestRate: 5,
        remainingMonths: 24,
        remainingInterest: 2000,
        repaidOverLastTwelveMonths: 8000,
      );

      expect(result, closeTo(30, 0.01));
    });

    test('charges one percent when more than a year remains', () {
      final result = service.compute(
        regime: CreditRegime.consumer,
        repaidCapital: 15000,
        remainingCapitalBefore: 18000,
        annualInterestRate: 5,
        remainingMonths: 24,
        remainingInterest: 2000,
      );

      expect(result, closeTo(150, 0.01));
    });

    test('charges half a percent when a year or less remains', () {
      final result = service.compute(
        regime: CreditRegime.consumer,
        repaidCapital: 15000,
        remainingCapitalBefore: 18000,
        annualInterestRate: 5,
        remainingMonths: 12,
        remainingInterest: 2000,
      );

      expect(result, closeTo(75, 0.01));
    });

    test('caps the indemnity at the remaining interest', () {
      final result = service.compute(
        regime: CreditRegime.consumer,
        repaidCapital: 15000,
        remainingCapitalBefore: 18000,
        annualInterestRate: 5,
        remainingMonths: 24,
        remainingInterest: 40,
      );

      expect(result, closeTo(40, 0.01));
    });
  });

  test('waives the indemnity when the contract has no such clause', () {
    final result = service.compute(
      regime: CreditRegime.mortgage,
      repaidCapital: 100000,
      remainingCapitalBefore: 100000,
      annualInterestRate: 3,
      remainingMonths: 120,
      remainingInterest: 20000,
      hasIndemnityClause: false,
    );

    expect(result, 0);
  });

  group('legal exemptions', () {
    for (final exemption in EarlyRepaymentExemption.values.where(
      (e) => e.exempts,
    )) {
      test('waives the indemnity for ${exemption.name}', () {
        final result = service.compute(
          regime: CreditRegime.mortgage,
          repaidCapital: 100000,
          remainingCapitalBefore: 100000,
          annualInterestRate: 3,
          remainingMonths: 120,
          remainingInterest: 20000,
          exemption: exemption,
        );

        expect(result, 0);
      });
    }
  });
}
