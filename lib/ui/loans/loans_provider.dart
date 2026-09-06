import 'package:mybudget/core/entities/early_repayment_quote.dart';
import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/core/entities/loan_event.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/models/loan_event_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'loans_provider.g.dart';

@Riverpod(keepAlive: true)
class LoanNotifier extends _$LoanNotifier {
  @override
  Future<List<Loan>> build() async {
    final loans = _loadLoans();

    loans.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      return b.startDate.compareTo(a.startDate);
    });

    return loans;
  }

  List<Loan> _loadLoans() {
    final models = ref.watch(loanRepositoryProvider).getAll();
    final events = ref.watch(loanEventRepositoryProvider).getAll();

    return ref
        .watch(loanServiceProvider)
        .createLoans(models, asOf: DateTime.now(), events: events);
  }

  Future<void> addLoan(LoanModel loan) async {
    final repo = ref.read(loanRepositoryProvider);
    repo.add(_withDerivedEndDate(loan));
    await _refresh();
  }

  Future<void> updateLoan(LoanModel loan) async {
    final repo = ref.read(loanRepositoryProvider);
    repo.update(_withDerivedEndDate(loan));
    await _refresh();
  }

  Future<void> deleteLoan(int id) async {
    ref.read(loanEventRepositoryProvider).deleteForLoan(id);
    ref.read(loanRepositoryProvider).delete(id);
    await _refresh();
  }

  Future<void> addEvent(LoanEventModel event) async {
    ref.read(loanEventRepositoryProvider).add(event);
    await _syncEndDate(event.loanId);
    await _refresh();
  }

  Future<void> deleteEvent(LoanEventModel event) async {
    ref.read(loanEventRepositoryProvider).delete(event.id);
    await _syncEndDate(event.loanId);
    await _refresh();
  }

  EarlyRepaymentQuote? quoteEarlyRepayment({
    required Loan loan,
    required LoanEvent event,
  }) {
    return ref.read(loanPayoffServiceProvider).quote(loan: loan, event: event);
  }

  List<LoanEventModel> eventsOf(int loanId) =>
      ref.read(loanEventRepositoryProvider).getForLoan(loanId);

  Future<void> _refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> _syncEndDate(int loanId) async {
    final repo = ref.read(loanRepositoryProvider);
    final model = repo.getAll().where((loan) => loan.id == loanId).firstOrNull;
    if (model == null) return;

    repo.update(_withDerivedEndDate(model));
  }

  LoanModel _withDerivedEndDate(LoanModel model) {
    final events = model.id == 0
        ? const <LoanEvent>[]
        : ref
              .read(loanEventRepositoryProvider)
              .getForLoan(model.id)
              .map((event) => event.toEntity())
              .toList();

    model.endDate = ref
        .read(loanServiceProvider)
        .endDateOf(model, events: events);

    return model;
  }

  List<Loan> _currentLoans() => state.value ?? [];

  List<Loan> getActiveLoans() =>
      _currentLoans().where((loan) => !loan.isCompleted).toList();

  List<Loan> getActiveLoansForAccount(int accountId) => _currentLoans()
      .where((loan) => loan.accountId == accountId && !loan.isCompleted)
      .toList();

  List<Loan> getCompletedLoans() =>
      _currentLoans().where((loan) => loan.isCompleted).toList();

  double getTotalRemainingAmount() =>
      getActiveLoans().fold(0.0, (sum, loan) => sum + loan.remainingCapital);

  double getTotalMonthlyPayments() =>
      getActiveLoans().fold(0.0, (sum, loan) => sum + loan.currentMonthlyPayment);

  double getTotalMonthlyPaymentsForAccount(int accountId) =>
      getActiveLoansForAccount(
        accountId,
      ).fold(0.0, (sum, loan) => sum + loan.currentMonthlyPayment);

  double getTotalActiveInitialAmount() =>
      getActiveLoans().fold(0.0, (sum, loan) => sum + loan.amount);

  double getTotalRemainingCost() =>
      getActiveLoans().fold(0.0, (sum, loan) => sum + loan.remainingCost);

  double getOverallProgressPercentage() {
    final activeLoans = getActiveLoans();
    if (activeLoans.isEmpty) return 0.0;

    final totalInitial = getTotalActiveInitialAmount();
    if (totalInitial == 0) return 0.0;

    final totalRemaining = getTotalRemainingAmount();
    return ((totalInitial - totalRemaining) / totalInitial).clamp(0.0, 1.0);
  }
}
