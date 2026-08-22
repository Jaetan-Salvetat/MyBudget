import 'package:mybudget/core/entities/loan_payment_breakdown.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/core/services/loan_calculation_service.dart';

class LoanPaymentBreakdownService {
  final LoanCalculationService _calculationService;

  const LoanPaymentBreakdownService(this._calculationService);

  LoanPaymentBreakdown calculateCurrentBreakdown({
    required LoanRepaymentType repaymentType,
    required double amount,
    required double interestRate,
    required int durationInMonths,
    required DateTime startDate,
    required DateTime currentDate,
    required int deferredMonths,
    required LoanInsuranceType insuranceType,
    required double insuranceValue,
    required InsuranceCalculationMode insuranceCalcMode,
    bool immediateFirstPayment = false,
  }) {
    final rawMonths = _calculateMonthsSinceStart(startDate, currentDate);
    final monthsSinceStart = immediateFirstPayment ? rawMonths + 1 : rawMonths;

    if (monthsSinceStart < deferredMonths) {
      return const LoanPaymentBreakdown.zero();
    }

    final remainingCapital = _calculationService.calculateRemainingCapital(
      repaymentType: repaymentType,
      amount: amount,
      interestRate: interestRate,
      durationInMonths: durationInMonths,
      startDate: startDate,
      currentDate: currentDate,
      deferredMonths: deferredMonths,
      immediateFirstPayment: immediateFirstPayment,
    );

    final interestPayment = _calculateCurrentInterestPayment(
      repaymentType: repaymentType,
      amount: amount,
      remainingCapital: remainingCapital,
      interestRate: interestRate,
    );

    final insurancePayment = _calculateCurrentInsurancePayment(
      amount: amount,
      insuranceType: insuranceType,
      insuranceValue: insuranceValue,
      calculationMode: insuranceCalcMode,
      remainingCapital: remainingCapital,
    );

    final totalPayment = _calculationService.calculateCurrentMonthlyPayment(
      repaymentType: repaymentType,
      amount: amount,
      interestRate: interestRate,
      durationInMonths: durationInMonths,
      startDate: startDate,
      currentDate: currentDate,
      deferredMonths: deferredMonths,
      insuranceType: insuranceType,
      insuranceValue: insuranceValue,
      insuranceCalcMode: insuranceCalcMode,
      immediateFirstPayment: immediateFirstPayment,
    );

    final capitalPayment = repaymentType == LoanRepaymentType.inFine
        ? 0.0
        : totalPayment - interestPayment - insurancePayment;

    return LoanPaymentBreakdown(
      capitalPayment: capitalPayment,
      interestPayment: interestPayment,
      insurancePayment: insurancePayment,
      totalPayment: totalPayment,
    );
  }

  LoanPaymentBreakdown calculateCumulativeBreakdown({
    required LoanRepaymentType repaymentType,
    required double amount,
    required double interestRate,
    required int durationInMonths,
    required DateTime startDate,
    required DateTime currentDate,
    required DateTime endDate,
    required int dayOfMonth,
    required int deferredMonths,
    required LoanInsuranceType insuranceType,
    required double insuranceValue,
    required InsuranceCalculationMode insuranceCalcMode,
    bool immediateFirstPayment = false,
  }) {
    if (currentDate.isBefore(startDate)) {
      return const LoanPaymentBreakdown.zero();
    }

    final monthlyPayment = _calculationService.calculateCurrentMonthlyPayment(
      repaymentType: repaymentType,
      amount: amount,
      interestRate: interestRate,
      durationInMonths: durationInMonths,
      startDate: startDate,
      currentDate: currentDate,
      deferredMonths: deferredMonths,
      insuranceType: insuranceType,
      insuranceValue: insuranceValue,
      insuranceCalcMode: insuranceCalcMode,
      immediateFirstPayment: immediateFirstPayment,
    );

    final totalPaid = _calculationService.calculateTotalPaidAmount(
      startDate: startDate,
      currentDate: currentDate,
      endDate: endDate,
      dayOfMonth: dayOfMonth,
      deferredMonths: deferredMonths,
      monthlyPayment: monthlyPayment,
      immediateFirstPayment: immediateFirstPayment,
    );

    final remainingCapital = _calculationService.calculateRemainingCapital(
      repaymentType: repaymentType,
      amount: amount,
      interestRate: interestRate,
      durationInMonths: durationInMonths,
      startDate: startDate,
      currentDate: currentDate,
      deferredMonths: deferredMonths,
      immediateFirstPayment: immediateFirstPayment,
    );

    final capitalPaid = amount - remainingCapital;

    final insurancePaid = _calculateCumulativeInsurance(
      startDate: startDate,
      currentDate: currentDate,
      deferredMonths: deferredMonths,
      amount: amount,
      insuranceType: insuranceType,
      insuranceValue: insuranceValue,
      calculationMode: insuranceCalcMode,
      repaymentType: repaymentType,
      interestRate: interestRate,
      durationInMonths: durationInMonths,
      immediateFirstPayment: immediateFirstPayment,
    );

    final interestsPaid = totalPaid - capitalPaid - insurancePaid;

    return LoanPaymentBreakdown(
      capitalPayment: capitalPaid,
      interestPayment: interestsPaid,
      insurancePayment: insurancePaid,
      totalPayment: totalPaid,
    );
  }

  double _calculateCurrentInterestPayment({
    required LoanRepaymentType repaymentType,
    required double amount,
    required double remainingCapital,
    required double interestRate,
  }) {
    final baseCapital = repaymentType == LoanRepaymentType.inFine
        ? amount
        : remainingCapital;

    return (baseCapital * interestRate / 100) / 12;
  }

  double _calculateCurrentInsurancePayment({
    required double amount,
    required LoanInsuranceType insuranceType,
    required double insuranceValue,
    required InsuranceCalculationMode calculationMode,
    required double remainingCapital,
  }) {
    if (insuranceType == LoanInsuranceType.none || insuranceValue <= 0) {
      return 0.0;
    }

    if (insuranceType == LoanInsuranceType.fixed) {
      return insuranceValue;
    }

    final baseCapital =
        calculationMode == InsuranceCalculationMode.initialCapital
        ? amount
        : remainingCapital;

    return (baseCapital * (insuranceValue / 100)) / 12;
  }

  double _calculateCumulativeInsurance({
    required DateTime startDate,
    required DateTime currentDate,
    required int deferredMonths,
    required double amount,
    required LoanInsuranceType insuranceType,
    required double insuranceValue,
    required InsuranceCalculationMode calculationMode,
    required LoanRepaymentType repaymentType,
    required double interestRate,
    required int durationInMonths,
    bool immediateFirstPayment = false,
  }) {
    if (insuranceType == LoanInsuranceType.none || insuranceValue <= 0) {
      return 0.0;
    }

    final rawMonths = _calculateMonthsSinceStart(startDate, currentDate);
    final monthsSinceStart = immediateFirstPayment ? rawMonths + 1 : rawMonths;
    final effectiveMonthsPaid = (monthsSinceStart - deferredMonths)
        .clamp(0, double.infinity)
        .toInt();

    if (effectiveMonthsPaid <= 0) return 0.0;

    if (insuranceType == LoanInsuranceType.fixed) {
      return insuranceValue * effectiveMonthsPaid;
    }

    if (calculationMode == InsuranceCalculationMode.initialCapital) {
      final monthlyInsurance = (amount * (insuranceValue / 100)) / 12;
      return monthlyInsurance * effectiveMonthsPaid;
    }

    final initialMonthly = (amount * (insuranceValue / 100)) / 12;

    final currentRemaining = _calculationService.calculateRemainingCapital(
      repaymentType: repaymentType,
      amount: amount,
      interestRate: interestRate,
      durationInMonths: durationInMonths,
      startDate: startDate,
      currentDate: currentDate,
      deferredMonths: deferredMonths,
      immediateFirstPayment: immediateFirstPayment,
    );

    final currentMonthly = (currentRemaining * (insuranceValue / 100)) / 12;

    final averageMonthly = (initialMonthly + currentMonthly) / 2;
    return averageMonthly * effectiveMonthsPaid;
  }

  int _calculateMonthsSinceStart(DateTime startDate, DateTime currentDate) {
    return (currentDate.year - startDate.year) * 12 +
        currentDate.month -
        startDate.month;
  }
}
