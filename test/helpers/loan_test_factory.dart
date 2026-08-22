import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/core/services/annual_percentage_rate_service.dart';
import 'package:mybudget/core/services/early_repayment_indemnity_service.dart';
import 'package:mybudget/core/services/loan_payoff_service.dart';
import 'package:mybudget/core/services/loan_schedule_service.dart';
import 'package:mybudget/core/services/loan_service.dart';
import 'package:mybudget/models/loan_event_model.dart';
import 'package:mybudget/models/loan_model.dart';

const LoanScheduleService testScheduleService = LoanScheduleService(
  EarlyRepaymentIndemnityService(),
);

const LoanService testLoanService = LoanService(
  testScheduleService,
  AnnualPercentageRateService(),
);

const LoanPayoffService testPayoffService = LoanPayoffService(
  testScheduleService,
);

Loan buildTestLoan(
  LoanModel model, {
  DateTime? asOf,
  List<LoanEventModel> events = const [],
}) {
  return testLoanService.createLoan(
    model,
    asOf: asOf ?? DateTime.now(),
    events: events,
  );
}
