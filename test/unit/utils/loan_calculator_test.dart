import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/utils/loan_calculator.dart';
import 'package:mybudget/core/enums/loan_enums.dart';

void main() {
  group('LoanCalculator', () {
    group('calculatePrincipalPayment', () {
      test('should return 0 if amount or duration is invalid', () {
        expect(
          LoanCalculator.calculatePrincipalPayment(
            amount: 0,
            annualRate: 5,
            durationInMonths: 12,
          ),
          0.0,
        );
        expect(
          LoanCalculator.calculatePrincipalPayment(
            amount: 1000,
            annualRate: 5,
            durationInMonths: 0,
          ),
          0.0,
        );
      });

      test('should use linear division if rate is 0', () {
        final result = LoanCalculator.calculatePrincipalPayment(
          amount: 1200,
          annualRate: 0,
          durationInMonths: 12,
        );
        expect(result, 100.0);
      });

      test('should calculate correct PMT for standard loan', () {
        final result = LoanCalculator.calculatePrincipalPayment(
          amount: 10000,
          annualRate: 5,
          durationInMonths: 12,
        );
        expect(result, closeTo(856.07, 0.01));
      });
    });

    group('calculateMonthlyInsurance', () {
      test('should return fixed value directly', () {
        final result = LoanCalculator.calculateMonthlyInsurance(
          amount: 10000,
          type: LoanInsuranceType.fixed,
          value: 15.0,
        );
        expect(result, 15.0);
      });

      test(
        'should calculate percentage based on initial capital per year / 12',
        () {
          final result = LoanCalculator.calculateMonthlyInsurance(
            amount: 10000,
            type: LoanInsuranceType.percentage,
            value: 0.36,
          );
          expect(result, 3.0);
        },
      );

      test('should return 0 for none', () {
        final result = LoanCalculator.calculateMonthlyInsurance(
          amount: 10000,
          type: LoanInsuranceType.none,
          value: 50,
        );
        expect(result, 0.0);
      });
    });

    group('calculateRemainingPrincipal (CRD)', () {
      test('should return full amount if monthsPassed is negative or 0', () {
        expect(
          LoanCalculator.calculateRemainingPrincipal(
            amount: 1000,
            annualRate: 5,
            durationInMonths: 12,
            monthsPassed: 0,
          ),
          1000.0,
        );
        expect(
          LoanCalculator.calculateRemainingPrincipal(
            amount: 1000,
            annualRate: 5,
            durationInMonths: 12,
            monthsPassed: -5,
          ),
          1000.0,
        );
      });

      test('should return 0 if duration passed or exceeded', () {
        expect(
          LoanCalculator.calculateRemainingPrincipal(
            amount: 1000,
            annualRate: 5,
            durationInMonths: 12,
            monthsPassed: 12,
          ),
          0.0,
        );
        expect(
          LoanCalculator.calculateRemainingPrincipal(
            amount: 1000,
            annualRate: 5,
            durationInMonths: 12,
            monthsPassed: 20,
          ),
          0.0,
        );
      });

      test('should decrease linearly if rate is 0', () {
        final result = LoanCalculator.calculateRemainingPrincipal(
          amount: 1200,
          annualRate: 0,
          durationInMonths: 12,
          monthsPassed: 6,
        );
        expect(result, 600.0);
      });

      test('should follow amortization curve if rate > 0', () {
        final result = LoanCalculator.calculateRemainingPrincipal(
          amount: 10000,
          annualRate: 5,
          durationInMonths: 12,
          monthsPassed: 1,
        );
        expect(result, closeTo(9185.60, 0.1));
      });

      test('should handle long duration (25 years) correctly', () {
        final result = LoanCalculator.calculateRemainingPrincipal(
          amount: 200000,
          annualRate: 2,
          durationInMonths: 300,
          monthsPassed: 150,
        );
        expect(result, greaterThan(100000));
        expect(result, closeTo(112425, 1.0));
      });

      test('should handle very low interest rate correctly', () {
        final result = LoanCalculator.calculateRemainingPrincipal(
          amount: 10000,
          annualRate: 0.1,
          durationInMonths: 12,
          monthsPassed: 1,
        );
        expect(result, closeTo(9167.04, 0.1));
      });
    });
  });
}
