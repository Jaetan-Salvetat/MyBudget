import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/core/entities/loan_event.dart';
import 'package:mybudget/core/services/annual_percentage_rate_service.dart';
import 'package:mybudget/core/services/loan_schedule_service.dart';
import 'package:mybudget/models/loan_event_model.dart';
import 'package:mybudget/models/loan_model.dart';

class LoanService {
  const LoanService(this._scheduleService, this._rateService);
  final LoanScheduleService _scheduleService;
  final AnnualPercentageRateService _rateService;

  Loan createLoan(
    LoanModel model, {
    required DateTime asOf,
    List<LoanEventModel> events = const [],
  }) {
    final terms = model.toTerms();
    final loanEvents = events.map((event) => event.toEntity()).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final schedule = _scheduleService.build(terms, events: loanEvents);
    final contractualSchedule = loanEvents.isEmpty
        ? schedule
        : _scheduleService.build(terms);

    return Loan(
      model: model,
      schedule: schedule,
      contractualSchedule: contractualSchedule,
      events: loanEvents,
      annualPercentageRate: _rateService.compute(
        schedule: contractualSchedule,
        originDate: terms.startDate,
      ),
      asOf: asOf,
    );
  }

  List<Loan> createLoans(
    List<LoanModel> models, {
    required DateTime asOf,
    List<LoanEventModel> events = const [],
  }) {
    final eventsByLoan = <int, List<LoanEventModel>>{};
    for (final event in events) {
      eventsByLoan.putIfAbsent(event.loanId, () => []).add(event);
    }

    return models
        .map(
          (model) => createLoan(
            model,
            asOf: asOf,
            events: eventsByLoan[model.id] ?? const [],
          ),
        )
        .toList();
  }

  DateTime endDateOf(LoanModel model, {List<LoanEvent> events = const []}) {
    final schedule = _scheduleService.build(model.toTerms(), events: events);
    return schedule.endDate ?? model.endDate;
  }
}
