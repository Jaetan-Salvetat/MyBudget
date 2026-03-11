import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/loan_payment_breakdown_service.dart';
import 'package:mybudget/core/services/loan_calculation_service.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';

void main() {
  late LoanPaymentBreakdownService service;

  setUp(() {
    const calculationService = LoanCalculationService();
    service = const LoanPaymentBreakdownService(calculationService);
  });

  group('LoanPaymentBreakdownService - Current Breakdown - Amortizable', () {
    test('should calculate breakdown correctly for first month', () {
      final breakdown = service.calculateCurrentBreakdown(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 1, 15),
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.none,
        insuranceValue: 0,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      expect(breakdown.capitalPayment, greaterThan(0));
      expect(breakdown.interestPayment, greaterThan(0));
      expect(breakdown.insurancePayment, 0.0);
      expect(breakdown.totalPayment, closeTo(856.07, 0.1));
    });

    test('should have higher capital and lower interest over time', () {
      final breakdownMonth1 = service.calculateCurrentBreakdown(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 1, 15),
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.none,
        insuranceValue: 0,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      final breakdownMonth6 = service.calculateCurrentBreakdown(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 6, 15),
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.none,
        insuranceValue: 0,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      expect(breakdownMonth6.capitalPayment, greaterThan(breakdownMonth1.capitalPayment));
      expect(breakdownMonth6.interestPayment, lessThan(breakdownMonth1.interestPayment));
    });

    test('should return zero breakdown during deferred period', () {
      final breakdown = service.calculateCurrentBreakdown(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 2, 15),
        deferredMonths: 3,
        insuranceType: LoanInsuranceType.none,
        insuranceValue: 0,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      expect(breakdown.capitalPayment, 0.0);
      expect(breakdown.interestPayment, 0.0);
      expect(breakdown.insurancePayment, 0.0);
      expect(breakdown.totalPayment, 0.0);
    });

    test('should include fixed insurance in breakdown', () {
      final breakdown = service.calculateCurrentBreakdown(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 1, 15),
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.fixed,
        insuranceValue: 25,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      expect(breakdown.insurancePayment, 25.0);
      expect(breakdown.totalPayment, closeTo(856.07 + 25, 0.1));
    });

    test('should include percentage insurance (CI) in breakdown', () {
      final breakdown = service.calculateCurrentBreakdown(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 1, 15),
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.percentage,
        insuranceValue: 0.36,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      expect(breakdown.insurancePayment, closeTo(3.0, 0.01));
    });

    test('should decrease insurance over time with CRD mode', () {
      final breakdownMonth1 = service.calculateCurrentBreakdown(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 1, 15),
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.percentage,
        insuranceValue: 0.36,
        insuranceCalcMode: InsuranceCalculationMode.remainingCapital,
      );

      final breakdownMonth6 = service.calculateCurrentBreakdown(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 6, 15),
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.percentage,
        insuranceValue: 0.36,
        insuranceCalcMode: InsuranceCalculationMode.remainingCapital,
      );

      expect(breakdownMonth6.insurancePayment, lessThan(breakdownMonth1.insurancePayment));
    });
  });

  group('LoanPaymentBreakdownService - Current Breakdown - In Fine', () {
    test('should have 0 capital payment until end', () {
      final breakdown = service.calculateCurrentBreakdown(
        repaymentType: LoanRepaymentType.inFine,
        amount: 10000,
        interestRate: 6,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 6, 15),
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.none,
        insuranceValue: 0,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      expect(breakdown.capitalPayment, 0.0);
      expect(breakdown.interestPayment, closeTo(50.0, 0.1));
      expect(breakdown.totalPayment, closeTo(50.0, 0.1));
    });

    test('should keep insurance constant for in fine (CI mode)', () {
      final breakdownMonth1 = service.calculateCurrentBreakdown(
        repaymentType: LoanRepaymentType.inFine,
        amount: 10000,
        interestRate: 6,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 1, 15),
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.percentage,
        insuranceValue: 0.36,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      final breakdownMonth11 = service.calculateCurrentBreakdown(
        repaymentType: LoanRepaymentType.inFine,
        amount: 10000,
        interestRate: 6,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 11, 15),
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.percentage,
        insuranceValue: 0.36,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      expect(breakdownMonth1.insurancePayment, closeTo(3.0, 0.01));
      expect(breakdownMonth11.insurancePayment, closeTo(3.0, 0.01));
    });
  });

  group('LoanPaymentBreakdownService - Cumulative Breakdown', () {
    test('should return zero before start date', () {
      final breakdown = service.calculateCumulativeBreakdown(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 2, 1),
        currentDate: DateTime(2024, 1, 1),
        endDate: DateTime(2025, 2, 1),
        dayOfMonth: 1,
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.none,
        insuranceValue: 0,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      expect(breakdown.capitalPayment, 0.0);
      expect(breakdown.interestPayment, 0.0);
      expect(breakdown.totalPayment, 0.0);
    });

    test('should calculate cumulative amounts correctly', () {
      final breakdown = service.calculateCumulativeBreakdown(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 7, 1),
        endDate: DateTime(2025, 1, 1),
        dayOfMonth: 1,
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.none,
        insuranceValue: 0,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      expect(breakdown.capitalPayment, greaterThan(0));
      expect(breakdown.interestPayment, greaterThan(0));
      expect(breakdown.totalPayment, closeTo(856.07 * 7, 1.0));
      expect(
        breakdown.capitalPayment + breakdown.interestPayment,
        closeTo(breakdown.totalPayment, 0.1),
      );
    });

    test('should not count deferred months in cumulative', () {
      final breakdown = service.calculateCumulativeBreakdown(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 4, 1),
        endDate: DateTime(2025, 1, 1),
        dayOfMonth: 1,
        deferredMonths: 3,
        insuranceType: LoanInsuranceType.none,
        insuranceValue: 0,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      expect(breakdown.totalPayment, greaterThan(0));
    });

    test('should accumulate fixed insurance correctly', () {
      final breakdown = service.calculateCumulativeBreakdown(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 4, 1),
        endDate: DateTime(2025, 1, 1),
        dayOfMonth: 1,
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.fixed,
        insuranceValue: 20,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      expect(breakdown.insurancePayment, 60.0);
    });

    test('should accumulate percentage insurance (CI) correctly', () {
      final breakdown = service.calculateCumulativeBreakdown(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 10000,
        interestRate: 5,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 4, 1),
        endDate: DateTime(2025, 1, 1),
        dayOfMonth: 1,
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.percentage,
        insuranceValue: 0.36,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      expect(breakdown.insurancePayment, closeTo(9.0, 0.01));
    });
  });

  group('LoanPaymentBreakdownService - Edge Cases', () {
    test('should handle 0% interest rate', () {
      final breakdown = service.calculateCurrentBreakdown(
        repaymentType: LoanRepaymentType.amortizable,
        amount: 12000,
        interestRate: 0,
        durationInMonths: 12,
        startDate: DateTime(2024, 1, 1),
        currentDate: DateTime(2024, 1, 15),
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.none,
        insuranceValue: 0,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );

      expect(breakdown.capitalPayment, 1000.0);
      expect(breakdown.interestPayment, 0.0);
      expect(breakdown.totalPayment, 1000.0);
    });
  });
}
