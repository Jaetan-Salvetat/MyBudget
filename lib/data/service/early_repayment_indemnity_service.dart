import 'dart:math';

import 'package:mybudget/core/enums/loan_event_types.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/core/utils/money.dart';

class EarlyRepaymentIndemnityService {
  const EarlyRepaymentIndemnityService();
  static const double _mortgageCapitalCapRate = 0.03;
  static const int _mortgageInterestMonths = 6;
  static const double _consumerYearlyFreeAllowance = 10000;
  static const double _consumerLongTermRate = 0.01;
  static const double _consumerShortTermRate = 0.005;
  static const int _consumerShortTermMonths = 12;

  double compute({
    required CreditRegime regime,
    required double repaidCapital,
    required double remainingCapitalBefore,
    required double annualInterestRate,
    required int remainingMonths,
    required double remainingInterest,
    EarlyRepaymentExemption exemption = EarlyRepaymentExemption.none,
    double repaidOverLastTwelveMonths = 0.0,
    bool hasIndemnityClause = true,
  }) {
    if (!hasIndemnityClause || exemption.exempts || repaidCapital <= 0) {
      return 0.0;
    }

    return switch (regime) {
      CreditRegime.mortgage => _mortgageIndemnity(
        repaidCapital: repaidCapital,
        remainingCapitalBefore: remainingCapitalBefore,
        annualInterestRate: annualInterestRate,
      ),
      CreditRegime.consumer => _consumerIndemnity(
        repaidCapital: repaidCapital,
        remainingMonths: remainingMonths,
        remainingInterest: remainingInterest,
        repaidOverLastTwelveMonths: repaidOverLastTwelveMonths,
      ),
    };
  }

  double _mortgageIndemnity({
    required double repaidCapital,
    required double remainingCapitalBefore,
    required double annualInterestRate,
  }) {
    final semesterInterest =
        repaidCapital *
        (annualInterestRate / 100) *
        _mortgageInterestMonths /
        12;
    final capitalCap = remainingCapitalBefore * _mortgageCapitalCapRate;

    return roundToCents(max(0, min(semesterInterest, capitalCap)));
  }

  double _consumerIndemnity({
    required double repaidCapital,
    required int remainingMonths,
    required double remainingInterest,
    required double repaidOverLastTwelveMonths,
  }) {
    final repaidThisYear = repaidOverLastTwelveMonths + repaidCapital;
    if (repaidThisYear <= _consumerYearlyFreeAllowance) return 0.0;

    final rate = remainingMonths > _consumerShortTermMonths
        ? _consumerLongTermRate
        : _consumerShortTermRate;

    return roundToCents(max(0, min(repaidCapital * rate, remainingInterest)));
  }
}
