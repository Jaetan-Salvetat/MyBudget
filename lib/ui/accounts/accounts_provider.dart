import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'accounts_provider.g.dart';

@Riverpod(keepAlive: true)
class AccountNotifier extends _$AccountNotifier {
  @override
  Future<List<AccountModel>> build() async {
    // Riverpod rebuild automatiquement quand ces providers changent
    // (remplace addListener/removeListener de l'ancien AccountViewModel)
    ref.watch(expenseProvider);
    ref.watch(revenueProvider);
    ref.watch(loanProvider);

    final repo = ref.watch(accountRepositoryProvider);
    return repo.getAll();
  }

  Future<void> addAccount(AccountModel account) async {
    final repo = ref.read(accountRepositoryProvider);
    repo.add(account);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateAccount(AccountModel account) async {
    final repo = ref.read(accountRepositoryProvider);
    repo.update(account);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteAccount(int id) async {
    final repo = ref.read(accountRepositoryProvider);
    repo.delete(id);
    ref.invalidateSelf();
    await future;
  }

  // ============= Calculs (utilisent les données des autres providers) =============

  double getAccountBalance(int accountId) {
    final expenses = ref.read(expenseProvider).value ?? [];
    final revenues = ref.read(revenueProvider).value ?? [];
    final loans = ref.read(loanProvider).value ?? [];

    final totalRevenues = revenues
        .where((r) => r.accountId == accountId)
        .fold<double>(0.0, (sum, r) => sum + r.amount);

    final totalExpenses = expenses
        .where((e) => e.accountId == accountId)
        .fold<double>(0.0, (sum, e) => sum + e.amount);

    final totalLoanPayments = loans
        .where((l) => l.accountId == accountId && !l.isCompleted)
        .fold<double>(0.0, (sum, l) => sum + l.currentMonthlyPayment);

    return totalRevenues - totalExpenses - totalLoanPayments;
  }

  double getTotalBalance() {
    final accounts = state.value ?? [];
    return accounts.fold(0.0, (sum, account) => sum + getAccountBalance(account.id));
  }

  double getNetCashFlow() {
    final expenseNotifier = ref.read(expenseProvider.notifier);
    final revenueNotifier = ref.read(revenueProvider.notifier);
    final loanNotifier = ref.read(loanProvider.notifier);

    final monthlyRevenues = revenueNotifier.getMonthlyRevenues();
    final monthlyExpenses = expenseNotifier.getMonthlyExpenses();
    final monthlyLoanPayments = loanNotifier.getTotalMonthlyPayments();

    return monthlyRevenues - (monthlyExpenses + monthlyLoanPayments);
  }

  double getSavingsRate() {
    final revenueNotifier = ref.read(revenueProvider.notifier);
    final monthlyRevenues = revenueNotifier.getMonthlyRevenues();
    if (monthlyRevenues <= 0) return 0.0;
    return (getNetCashFlow() / monthlyRevenues) * 100;
  }

  int getTotalTransactionsCount() {
    final expenses = ref.read(expenseProvider).value ?? [];
    final revenues = ref.read(revenueProvider).value ?? [];
    final loanNotifier = ref.read(loanProvider.notifier);
    return expenses.length + revenues.length + loanNotifier.getActiveLoans().length;
  }
}
