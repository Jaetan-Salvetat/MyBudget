import 'dart:math';

import 'package:mybudget/core/entities/loan_event.dart';
import 'package:mybudget/core/entities/loan_installment.dart';
import 'package:mybudget/core/entities/loan_schedule.dart';
import 'package:mybudget/core/entities/loan_terms.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_event_types.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/core/services/early_repayment_indemnity_service.dart';
import 'package:mybudget/core/utils/money.dart';

class LoanScheduleService {
  static const double _settledCapital = 0.005;
  static const int _indemnityWindowMonths = 12;

  final EarlyRepaymentIndemnityService _indemnityService;

  const LoanScheduleService(this._indemnityService);

  LoanSchedule build(LoanTerms terms, {List<LoanEvent> events = const []}) {
    return _build(terms, events, withIndemnities: true);
  }

  LoanSchedule _build(
    LoanTerms terms,
    List<LoanEvent> events, {
    required bool withIndemnities,
  }) {
    final installments = <LoanInstallment>[];

    if (terms.amount <= 0 || terms.effectiveDuration <= 0) {
      return LoanSchedule(
        installments: installments,
        borrowedAmount: terms.amount,
        fees: terms.fees,
      );
    }

    final pending = [...events]..sort((a, b) => a.date.compareTo(b.date));
    final applied = <LoanEvent>[];
    final settledRepayments = <DateTime, double>{};

    final lastPlanned = terms.effectiveDuration;
    final deferred = terms.effectiveDeferredMonths;
    final isInFine = terms.repaymentType == LoanRepaymentType.inFine;

    var capital = terms.amount;
    var payment = 0.0;
    var mustRecomputePayment = true;
    var number = 0;

    while (number < lastPlanned && capital > _settledCapital) {
      number++;
      final date = _installmentDate(terms, number);
      final opening = capital;
      final insurance = _insurancePremium(terms, opening);
      final accruedInterest = _isUpfrontInstallment(terms, number)
          ? 0.0
          : roundToCents(opening * terms.monthlyInterestRate);

      late final double interest;
      late final double principal;
      late final LoanInstallmentKind kind;

      if (number <= deferred) {
        interest = accruedInterest;
        final capitalizes = terms.deferralType == LoanDeferralType.total;
        principal = capitalizes ? -accruedInterest : 0.0;
        kind = capitalizes
            ? LoanInstallmentKind.deferredTotal
            : LoanInstallmentKind.deferredPartial;
      } else if (isInFine) {
        interest = accruedInterest;
        principal = number == lastPlanned ? opening : 0.0;
        kind = LoanInstallmentKind.interestOnly;
      } else {
        if (mustRecomputePayment) {
          payment = _annuity(
            opening,
            terms.monthlyInterestRate,
            lastPlanned - number + 1,
            upfront: _isUpfrontInstallment(terms, number),
          );
          mustRecomputePayment = false;
        }
        interest = accruedInterest;
        final scheduled = roundToCents(payment - interest);
        principal = (number == lastPlanned || scheduled > opening)
            ? opening
            : scheduled;
        kind = LoanInstallmentKind.amortizing;
      }

      var closing = roundToCents(opening - principal);
      var earlyPrincipal = 0.0;
      var indemnity = 0.0;

      while (pending.isNotEmpty && !pending.first.date.isAfter(date)) {
        final event = pending.removeAt(0);
        applied.add(event);
        if (closing <= _settledCapital) continue;

        final repaid = event.isTotalRepayment
            ? closing
            : min(roundToCents(event.amount), closing);
        if (repaid <= 0) continue;

        if (withIndemnities) {
          indemnity += _indemnityService.compute(
            regime: terms.effectiveRegime,
            repaidCapital: repaid,
            remainingCapitalBefore: closing,
            annualInterestRate: terms.effectiveAnnualInterestRate,
            remainingMonths: lastPlanned - number,
            remainingInterest: _contractualInterestAfter(
              terms,
              applied.sublist(0, applied.length - 1),
              number,
            ),
            exemption: event.exemption,
            hasIndemnityClause: terms.hasIndemnityClause,
            repaidOverLastTwelveMonths: _repaidWithinWindow(
              settledRepayments,
              date,
            ),
          );
        }

        settledRepayments[date] = (settledRepayments[date] ?? 0) + repaid;
        earlyPrincipal += repaid;
        closing = roundToCents(closing - repaid);

        if (event.reamortizationMode == ReamortizationMode.reducePayment) {
          mustRecomputePayment = true;
        }
      }

      installments.add(
        LoanInstallment(
          number: number,
          date: date,
          openingCapital: opening,
          interest: interest,
          insurance: insurance,
          principal: principal,
          earlyPrincipal: earlyPrincipal,
          indemnity: roundToCents(indemnity),
          closingCapital: closing,
          kind: earlyPrincipal > 0 ? LoanInstallmentKind.earlyRepayment : kind,
        ),
      );

      capital = closing;
    }

    return LoanSchedule(
      installments: installments,
      borrowedAmount: terms.amount,
      fees: terms.fees,
    );
  }

  double _contractualInterestAfter(
    LoanTerms terms,
    List<LoanEvent> earlierEvents,
    int installmentNumber,
  ) {
    final continuation = _build(terms, earlierEvents, withIndemnities: false);

    return roundToCents(
      continuation.installments
          .where((installment) => installment.number > installmentNumber)
          .fold(0.0, (sum, installment) => sum + installment.interest),
    );
  }

  bool _isUpfrontInstallment(LoanTerms terms, int number) =>
      terms.immediateFirstPayment && number == 1;

  DateTime _installmentDate(LoanTerms terms, int number) {
    if (_isUpfrontInstallment(terms, number)) return terms.startDate;

    final offset = terms.immediateFirstPayment ? number - 1 : number;
    final month = DateTime(
      terms.startDate.year,
      terms.startDate.month + offset,
      1,
    );
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0).day;

    return DateTime(
      month.year,
      month.month,
      min(terms.dayOfMonth, lastDayOfMonth),
    );
  }

  double _insurancePremium(LoanTerms terms, double openingCapital) {
    if (terms.insuranceType == LoanInsuranceType.none ||
        terms.insuranceValue <= 0) {
      return 0.0;
    }

    if (terms.insuranceType == LoanInsuranceType.fixed) {
      return roundToCents(terms.insuranceValue);
    }

    final base =
        terms.insuranceCalculationMode ==
            InsuranceCalculationMode.initialCapital
        ? terms.amount
        : openingCapital;

    return roundToCents(base * terms.insuranceValue / 100 / 12);
  }

  double _annuity(
    double capital,
    double monthlyRate,
    int months, {
    bool upfront = false,
  }) {
    if (months <= 0 || capital <= 0) return 0.0;
    if (monthlyRate <= 0) return roundToCents(capital / months);

    final discount = 1 - pow(1 + monthlyRate, -months);
    if (discount <= 0) return roundToCents(capital / months);

    final ordinary = capital * monthlyRate / discount;
    final annuity = upfront ? ordinary / (1 + monthlyRate) : ordinary;

    return annuity.isFinite
        ? roundToCents(annuity)
        : roundToCents(capital / months);
  }

  double _repaidWithinWindow(Map<DateTime, double> repayments, DateTime date) {
    final windowStart = DateTime(
      date.year,
      date.month - _indemnityWindowMonths,
      date.day,
    );

    return repayments.entries
        .where((entry) => entry.key.isAfter(windowStart))
        .fold(0.0, (sum, entry) => sum + entry.value);
  }
}
