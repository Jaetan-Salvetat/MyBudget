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
        insuranceValue: 0.36,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      expect(result, closeTo(856.07 + 3, 0.1));
    });

    test('should calculate insurance on CRD (remaining capital)', () {
      final result = service.calculateCurrentMonthlyPayment(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 7, 1),
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.percentage,
        insuranceValue: 0.36,
        insuranceCalcMode: InsuranceCalculationMode.remainingCapital,
      );

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
        currentDate: DateTime(2024, 7, 1),
        deferredMonths: 0,
      );

      expect(result, 600.0);
    });

    test('should handle deferred months in calculation', () {
      final result = service.calculateRemainingCapital(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 4, 1),
        deferredMonths: 3,
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
        currentDate: DateTime(2024, 4, 1),
        endDate: DateTime(2025, 1, 1),
        dayOfMonth: 1,
        deferredMonths: 3,
        monthlyPayment: 100,
      );

      expect(result, 100.0);
    });

    test('should calculate total paid correctly', () {
      final result = service.calculateTotalPaidAmount(
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 7, 1),
        endDate: DateTime(2025, 1, 1),
        dayOfMonth: 1,
        deferredMonths: 0,
        monthlyPayment: 100,
      );

      expect(result, 700.0);
    });

    test('should handle day of month correctly', () {
      final result = service.calculateTotalPaidAmount(
        startDate: DateTime(2024, 1, 15),
        currentDate: DateTime(2024, 3, 10),
        endDate: DateTime(2025, 1, 15),
        dayOfMonth: 15,
        deferredMonths: 0,
        monthlyPayment: 100,
      );

      expect(result, 200.0);
    });

    test('should cap at end date if current date is after', () {
      final result = service.calculateTotalPaidAmount(
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 1, 1),
        dayOfMonth: 1,
        deferredMonths: 0,
        monthlyPayment: 100,
      );

      expect(result, 1300.0);
    });
  });

  group('LoanCalculationService - immediateFirstPayment', () {
    test('remainingCapital counts start month as first payment', () {
      final withImmediate = service.calculateRemainingCapital(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 3000,
        interestRate: 0,
        durationInMonths: 3,
        startDate: DateTime(2026, 5, 8),
        currentDate: DateTime(2026, 5, 8),
        deferredMonths: 0,
        immediateFirstPayment: true,
      );

      final withoutImmediate = service.calculateRemainingCapital(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 3000,
        interestRate: 0,
        durationInMonths: 3,
        startDate: DateTime(2026, 5, 8),
        currentDate: DateTime(2026, 5, 8),
        deferredMonths: 0,
        immediateFirstPayment: false,
      );

      expect(withoutImmediate, 3000.0);
      expect(withImmediate, 2000.0);
    });

    test('remainingMonths uses endDate directly (already adjusted for immediate)', () {
      final withImmediate = service.calculateRemainingMonths(
        currentDate: DateTime(2026, 5, 8),
        endDate: DateTime(2026, 7, 8),
        startDate: DateTime(2026, 5, 8),
        durationInMonths: 3,
        immediateFirstPayment: true,
      );

      final withoutImmediate = service.calculateRemainingMonths(
        currentDate: DateTime(2026, 5, 8),
        endDate: DateTime(2026, 8, 8),
        startDate: DateTime(2026, 5, 8),
        durationInMonths: 3,
        immediateFirstPayment: false,
      );

      expect(withoutImmediate, 3);
      expect(withImmediate, 2);
    });

    test('totalPaidAmount counts start month with immediate payment', () {
      final result = service.calculateTotalPaidAmount(
        startDate: DateTime(2026, 5, 8),
        currentDate: DateTime(2026, 5, 8),
        endDate: DateTime(2026, 7, 8),
        dayOfMonth: 8,
        deferredMonths: 0,
        monthlyPayment: 1000,
        immediateFirstPayment: true,
      );

      expect(result, 1000.0);
    });

    test('totalPaidAmount is 0 on start date without immediate payment', () {
      final result = service.calculateTotalPaidAmount(
        startDate: DateTime(2026, 5, 8),
        currentDate: DateTime(2026, 5, 8),
        endDate: DateTime(2026, 8, 8),
        dayOfMonth: 8,
        deferredMonths: 0,
        monthlyPayment: 1000,
        immediateFirstPayment: false,
      );

      expect(result, 1000.0);
    });

    test('3-month loan with immediate payment completes in 2 months', () {
      final remaining = service.calculateRemainingCapital(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 3000,
        interestRate: 0,
        durationInMonths: 3,
        startDate: DateTime(2026, 5, 1),
        currentDate: DateTime(2026, 7, 1),
        deferredMonths: 0,
        immediateFirstPayment: true,
      );

      expect(remaining, 0.0);
    });
  });
}
