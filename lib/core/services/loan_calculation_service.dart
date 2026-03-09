import 'dart:math';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';

class LoanCalculationService {
  const LoanCalculationService();

  double calculateCurrentMonthlyPayment({
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
  }) {
    final monthsSinceStart = _calculateMonthsSinceStart(startDate, currentDate);

    if (monthsSinceStart < deferredMonths) {
      return 0.0;
    }

    final remainingCapital = calculateRemainingCapital(
      repaymentType: repaymentType,
      amount: amount,
      interestRate: interestRate,
      durationInMonths: durationInMonths,
      startDate: startDate,
      currentDate: currentDate,
      deferredMonths: deferredMonths,
    );

    final loanPayment = repaymentType == LoanRepaymentType.inFine
        ? _calculateInFineMonthlyPayment(amount, interestRate)
        : _calculateAmortizableMonthlyPayment(
            amount,
            interestRate,
            durationInMonths - deferredMonths,
          );

    final insurancePayment = _calculateInsurancePayment(
      amount: amount,
      insuranceType: insuranceType,
      insuranceValue: insuranceValue,
      calculationMode: insuranceCalcMode,
      remainingCapital: remainingCapital,
    );

    return loanPayment + insurancePayment;
  }

  double calculateRemainingCapital({
    required LoanRepaymentType repaymentType,
    required double amount,
    required double interestRate,
    required int durationInMonths,
    required DateTime startDate,
    required DateTime currentDate,
    required int deferredMonths,
  }) {
    if (currentDate.isBefore(startDate)) {
      return amount;
    }

    final monthsSinceStart = _calculateMonthsSinceStart(startDate, currentDate);

    if (monthsSinceStart < deferredMonths) {
      return amount;
    }

    if (repaymentType == LoanRepaymentType.inFine) {
      return amount;
    }

    final effectiveDuration = durationInMonths - deferredMonths;
    final effectiveMonthsPassed = monthsSinceStart - deferredMonths;

    return _calculateAmortizableRemainingCapital(
      amount: amount,
      interestRate: interestRate,
      durationInMonths: effectiveDuration,
      monthsPassed: effectiveMonthsPassed,
    );
  }

  int calculateRemainingMonths({
    required DateTime currentDate,
    required DateTime endDate,
    required DateTime startDate,
    required int durationInMonths,
  }) {
    if (currentDate.isAfter(endDate)) return 0;
    if (currentDate.isBefore(startDate)) return durationInMonths;

    final endYearMonth = endDate.year * 12 + endDate.month;
    final nowYearMonth = currentDate.year * 12 + currentDate.month;

    final diff = endYearMonth - nowYearMonth;
    return diff.clamp(0, durationInMonths);
  }

  double calculateTotalPaidAmount({
    required DateTime startDate,
    required DateTime currentDate,
    required DateTime endDate,
    required int dayOfMonth,
    required int deferredMonths,
    required double monthlyPayment,
  }) {
    if (currentDate.isBefore(startDate)) {
      return 0.0;
    }

    final effectiveEndDate = currentDate.isAfter(endDate) ? endDate : currentDate;

    final startYearMonth = startDate.year * 12 + startDate.month - 1;
    final endYearMonth = effectiveEndDate.year * 12 + effectiveEndDate.month - 1;
    final daysPassed = effectiveEndDate.day >= dayOfMonth ? 1 : 0;

    final totalMonthsPassed = (endYearMonth - startYearMonth) + daysPassed;
    final effectiveMonthsPaid = (totalMonthsPassed - deferredMonths).clamp(0, double.infinity).toInt();

    return effectiveMonthsPaid * monthlyPayment;
  }

  double _calculateInFineMonthlyPayment(
    double amount,
    double interestRate,
  ) {
    return (amount * interestRate / 100) / 12;
  }

  double _calculateAmortizableMonthlyPayment(
    double amount,
    double interestRate,
    int durationInMonths,
  ) {
    if (amount <= 0 || durationInMonths <= 0) return 0.0;
    if (interestRate == 0) return amount / durationInMonths;

    final monthlyRate = interestRate / 100 / 12;
    return amount * (monthlyRate / (1 - pow(1 + monthlyRate, -durationInMonths)));
  }

  double _calculateAmortizableRemainingCapital({
    required double amount,
    required double interestRate,
    required int durationInMonths,
    required int monthsPassed,
  }) {
    if (monthsPassed <= 0) return amount;
    if (monthsPassed >= durationInMonths) return 0.0;

    if (interestRate == 0) {
      return amount - (amount / durationInMonths * monthsPassed);
    }

    final monthlyRate = interestRate / 100 / 12;
    final numerator = pow(1 + monthlyRate, durationInMonths) -
        pow(1 + monthlyRate, monthsPassed);
    final denominator = pow(1 + monthlyRate, durationInMonths) - 1;

    return amount * (numerator / denominator);
  }

  double _calculateInsurancePayment({
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

    final baseCapital = calculationMode == InsuranceCalculationMode.initialCapital
        ? amount
        : remainingCapital;

    return (baseCapital * (insuranceValue / 100)) / 12;
  }

  int _calculateMonthsSinceStart(DateTime startDate, DateTime currentDate) {
    return (currentDate.year - startDate.year) * 12 +
        currentDate.month -
        startDate.month;
  }
}
