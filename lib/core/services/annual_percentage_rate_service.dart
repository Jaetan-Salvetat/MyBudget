import 'dart:math';

import 'package:mybudget/core/entities/loan_schedule.dart';

class AnnualPercentageRateService {
  const AnnualPercentageRateService();
  static const double _maxMonthlyRate = 1.0;
  static const double _tolerance = 1e-9;
  static const int _maxIterations = 200;
  static const int _decimals = 3;

  static final double _saturatedRate = double.parse(
    ((pow(1 + _maxMonthlyRate, 12) - 1) * 100).toStringAsFixed(_decimals),
  );

  double compute({
    required LoanSchedule schedule,
    required DateTime originDate,
  }) {
    if (schedule.isEmpty) return 0.0;

    final netAmount = schedule.borrowedAmount - schedule.fees;
    if (netAmount <= 0) return _saturatedRate;

    final flows = schedule.installments
        .map(
          (installment) => (
            months: _monthsBetween(originDate, installment.date),
            amount: installment.totalPayment,
          ),
        )
        .toList();

    if (_netPresentValue(flows, 0, netAmount) <= 0) return 0.0;

    var low = 0.0;
    var high = _maxMonthlyRate;

    for (var iteration = 0; iteration < _maxIterations; iteration++) {
      final middle = (low + high) / 2;
      final value = _netPresentValue(flows, middle, netAmount);

      if (value.abs() < _tolerance) {
        low = middle;
        break;
      }

      if (value > 0) {
        low = middle;
      } else {
        high = middle;
      }
    }

    final annualRate = (pow(1 + low, 12) - 1) * 100;
    return double.parse(annualRate.toStringAsFixed(_decimals));
  }

  double _netPresentValue(
    List<({int months, double amount})> flows,
    double monthlyRate,
    double netAmount,
  ) {
    var present = 0.0;
    for (final flow in flows) {
      present += flow.amount / pow(1 + monthlyRate, flow.months);
    }
    return present - netAmount;
  }

  int _monthsBetween(DateTime origin, DateTime date) {
    final months = (date.year - origin.year) * 12 + date.month - origin.month;
    return months < 0 ? 0 : months;
  }
}
