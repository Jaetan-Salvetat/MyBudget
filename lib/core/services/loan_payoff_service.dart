import 'package:mybudget/core/entities/early_repayment_quote.dart';
import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/core/entities/loan_event.dart';
import 'package:mybudget/core/entities/loan_installment.dart';
import 'package:mybudget/core/entities/loan_schedule.dart';
import 'package:mybudget/core/services/loan_schedule_service.dart';
import 'package:mybudget/core/utils/money.dart';

class LoanPayoffService {
  static const double _bankMinimumRatio = 0.1;

  final LoanScheduleService _scheduleService;

  const LoanPayoffService(this._scheduleService);

  EarlyRepaymentQuote? quote({required Loan loan, required LoanEvent event}) {
    final candidate = _scheduleService.build(
      loan.model.toTerms(),
      events: [...loan.events, event],
    );

    final settlement = _settlementOf(candidate, event.date);
    if (settlement == null) return null;

    final baseline = _installmentOn(loan.schedule, settlement.date);
    final alreadyRepaid = baseline?.earlyPrincipal ?? 0.0;
    final alreadyCharged = baseline?.indemnity ?? 0.0;

    final repaidCapital = roundToCents(
      settlement.earlyPrincipal - alreadyRepaid,
    );
    if (repaidCapital <= 0) return null;

    final remainingBefore = roundToCents(
      settlement.openingCapital - settlement.principal - alreadyRepaid,
    );

    return EarlyRepaymentQuote(
      settlementDate: settlement.date,
      remainingCapitalBefore: remainingBefore,
      repaidCapital: repaidCapital,
      indemnity: roundToCents(settlement.indemnity - alreadyCharged),
      settlementPayment: settlement.scheduledPayment,
      costSaved: roundToCents(loan.schedule.totalCost - candidate.totalCost),
      monthsSaved: loan.schedule.installmentCount - candidate.installmentCount,
      newMonthlyPayment: candidate.currentPaymentAt(settlement.date),
      newEndDate: candidate.isCompletedAt(settlement.date)
          ? null
          : candidate.endDate,
      isBelowBankMinimum:
          !event.isTotalRepayment &&
          repaidCapital < loan.amount * _bankMinimumRatio,
    );
  }

  LoanInstallment? _settlementOf(LoanSchedule schedule, DateTime date) {
    for (final installment in schedule.installments) {
      if (installment.date.isBefore(date)) continue;
      return installment.hasEarlyRepayment ? installment : null;
    }
    return null;
  }

  LoanInstallment? _installmentOn(LoanSchedule schedule, DateTime date) {
    for (final installment in schedule.installments) {
      if (installment.date == date) return installment;
    }
    return null;
  }
}
