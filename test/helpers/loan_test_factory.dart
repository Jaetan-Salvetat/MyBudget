import 'package:mybudget/core/values/loan.dart';
import 'package:mybudget/data/model/loan_event_model.dart';
import 'package:mybudget/data/model/loan_model.dart';
import 'package:mybudget/data/service/annual_percentage_rate_service.dart';
import 'package:mybudget/data/service/early_repayment_indemnity_service.dart';
import 'package:mybudget/data/service/loan_payoff_service.dart';
import 'package:mybudget/data/service/loan_schedule_service.dart';
import 'package:mybudget/data/service/loan_service.dart';

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
