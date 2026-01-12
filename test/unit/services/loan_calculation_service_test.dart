import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/loan_calculation_service.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';

void main() {
  late LoanCalculationService service;

  setUp(() {
    service = const LoanCalculationService();
  });

  group('LoanCalculationService - calculateCurrentMonthlyPayment', () {
    test('should return 0 during deferred period', () {
      final result = service.calculateCurrentMonthlyPayment(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 1, 15),
        deferredMonths: 3,
        insuranceType: LoanInsuranceType.none,
        insuranceValue: 0,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      expect(result, 0.0);
    });

    test('should calculate amortizable loan payment correctly', () {
      final result = service.calculateCurrentMonthlyPayment(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 2, 1),
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.none,
        insuranceValue: 0,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      expect(result, closeTo(856.07, 0.1));
    });

    test('should calculate in fine loan payment correctly (only interests)', () {
      final result = service.calculateCurrentMonthlyPayment(
        repaymentType: LoanRepaymentType.inFine,
        amount: 10000,
        interestRate: 6,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 2, 1),
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.none,
        insuranceValue: 0,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      // In fine: only interests = 10000 * 6% / 12 = 50
      expect(result, closeTo(50.0, 0.1));
    });

    test('should add fixed insurance to monthly payment', () {
      final result = service.calculateCurrentMonthlyPayment(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 2, 1),
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.fixed,
        insuranceValue: 20,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      expect(result, closeTo(856.07 + 20, 0.1));
    });

    test('should add percentage insurance (CI mode) to monthly payment', () {
      final result = service.calculateCurrentMonthlyPayment(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 2, 1),
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.percentage,
        insuranceValue: 0.36, // 0.36% annually
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      // Insurance: 10000 * 0.36% / 12 = 3
      expect(result, closeTo(856.07 + 3, 0.1));
    });

    test('should calculate insurance on CRD (remaining capital)', () {
      final result = service.calculateCurrentMonthlyPayment(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 7, 1), // 6 months passed
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.percentage,
        insuranceValue: 0.36,
        insuranceCalcMode: InsuranceCalculationMode.remainingCapital,
      );

      // Insurance should be less than CI because remaining capital < initial
      const insuranceCI = 10000 * 0.36 / 100 / 12;
      final insuranceCRD = result - 856.07;
      expect(insuranceCRD, lessThan(insuranceCI));
    });
  });

  group('LoanCalculationService - calculateRemainingCapital', () {
    test('should return full amount before start date', () {
      final result = service.calculateRemainingCapital(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 2, 1),
        currentDate: DateTime(2024, 1, 1),
        deferredMonths: 0,
      );

      expect(result, 10000.0);
    });

    test('should return full amount during deferred period', () {
      final result = service.calculateRemainingCapital(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 3, 1),
        deferredMonths: 6,
      );

      expect(result, 10000.0);
    });

    test('should return full amount for in fine loan', () {
      final result = service.calculateRemainingCapital(
        repaymentType: LoanRepaymentType.inFine,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 6, 1),
        deferredMonths: 0,
      );

      // In fine: capital stays constant until end
      expect(result, 10000.0);
    });

    test('should calculate amortizable remaining capital correctly', () {
      final result = service.calculateRemainingCapital(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 2, 1),
        deferredMonths: 0,
      );

      // After 1 month, capital should have decreased
      expect(result, lessThan(10000));
      expect(result, closeTo(9185.60, 1.0));
    });

    test('should return 0 if rate is 0', () {
      final result = service.calculateRemainingCapital(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 1200,
        interestRate: 0,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 7, 1), // 6 months
        deferredMonths: 0,
      );

      // Linear decrease: 1200 - (1200/12 * 6) = 600
      expect(result, 600.0);
    });

    test('should handle deferred months in calculation', () {
      final result = service.calculateRemainingCapital(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 4, 1), // 3 months after start
        deferredMonths: 3, // 3 months deferred, so no payment yet
      );

      expect(result, 10000.0);
    });
  });

  group('LoanCalculationService - calculateRemainingMonths', () {
    test('should return 0 if current date is after end date', () {
      final result = service.calculateRemainingMonths(
        currentDate: DateTime(2025, 1, 1),
        endDate: DateTime(2024, 12, 31),
        startDate: DateTime(2024, 1, 1),
        durationInMonths: 12,
      );

      expect(result, 0);
    });

    test('should return full duration if before start date', () {
      final result = service.calculateRemainingMonths(
        currentDate: DateTime(2023, 12, 1),
        endDate: DateTime(2024, 12, 1),
        startDate: DateTime(2024, 1, 1),
        durationInMonths: 12,
      );

      expect(result, 12);
    });

    test('should calculate remaining months correctly', () {
      final result = service.calculateRemainingMonths(
        currentDate: DateTime(2024, 7, 1),
        endDate: DateTime(2025, 1, 1),
        startDate: DateTime(2024, 1, 1),
        durationInMonths: 12,
      );

      expect(result, 6);
    });
  });

  group('LoanCalculationService - calculateTotalPaidAmount', () {
    test('should return 0 before start date', () {
      final result = service.calculateTotalPaidAmount(
        startDate: DateTime(2024, 2, 1),
        currentDate: DateTime(2024, 1, 1),
        endDate: DateTime(2025, 2, 1),
        dayOfMonth: 1,
        deferredMonths: 0,
        monthlyPayment: 100,
      );

      expect(result, 0.0);
    });

    test('should not count deferred months in total paid', () {
      final result = service.calculateTotalPaidAmount(
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 4, 1), // 3 months after start
        endDate: DateTime(2025, 1, 1),
        dayOfMonth: 1,
        deferredMonths: 3,
        monthlyPayment: 100,
      );

      // 4 months passed (Jan, Feb, Mar, Apr), 3 deferred, so 1 payment
      expect(result, 100.0);
    });

    test('should calculate total paid correctly', () {
      final result = service.calculateTotalPaidAmount(
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 7, 1), // 6 months after start
        endDate: DateTime(2025, 1, 1),
        dayOfMonth: 1,
        deferredMonths: 0,
        monthlyPayment: 100,
      );

      // Jan, Feb, Mar, Apr, May, Jun, Jul = 7 payments
      expect(result, 700.0);
    });

    test('should handle day of month correctly', () {
      final result = service.calculateTotalPaidAmount(
        startDate: DateTime(2024, 1, 15),
        currentDate: DateTime(2024, 3, 10), // Before day 15
        endDate: DateTime(2025, 1, 15),
        dayOfMonth: 15,
        deferredMonths: 0,
        monthlyPayment: 100,
      );

      // Jan 15, Feb 15 = 2 payments made, March 15 not yet
      expect(result, 200.0);
    });

    test('should cap at end date if current date is after', () {
      final result = service.calculateTotalPaidAmount(
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2025, 6, 1), // After end date
        endDate: DateTime(2025, 1, 1),
        dayOfMonth: 1,
        deferredMonths: 0,
        monthlyPayment: 100,
      );

      // 13 months (Jan 2024 to Jan 2025 inclusive)
      expect(result, 1300.0);
    });
  });
}
