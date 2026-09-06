import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/data/provider/expenses_provider.dart';
import 'package:mybudget/data/provider/loans_provider.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/provider/revenues_provider.dart';
import 'package:mybudget/data/provider/transfers_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'accounts_provider.g.dart';

@Riverpod(keepAlive: true)
class AccountNotifier extends _$AccountNotifier {
  @override
  List<AccountModel> build() {
    ref.watch(expenseProvider);
    ref.watch(revenueProvider);
    ref.watch(loanProvider);
    ref.watch(transferProvider);

    return ref.watch(accountRepositoryProvider).getAll();
  }

  void addAccount(AccountModel account) {
    final repo = ref.read(accountRepositoryProvider);
    repo.add(account);
    state = repo.getAll();
  }

  void updateAccount(AccountModel account) {
    final repo = ref.read(accountRepositoryProvider);
    repo.update(account);
    state = repo.getAll();
  }

  void deleteAccount(int id) {
    final repo = ref.read(accountRepositoryProvider);
    repo.delete(id);
    state = repo.getAll();
  }

  double getAccountBalance(int accountId) {
    final expenses = ref.read(expenseProvider).value ?? [];
    final revenues = ref.read(revenueProvider).value ?? [];
    final loans = ref.read(loanProvider).value ?? [];

    final totalRevenues = revenues
        .where((r) => r.accountId == accountId && r.endDate == null)
        .fold<double>(0.0, (sum, r) => sum + r.amount);

    final totalExpenses = expenses
        .where((e) => e.accountId == accountId && e.endDate == null)
        .fold<double>(0.0, (sum, e) => sum + e.amount);

    final totalLoanPayments = loans
        .where((l) => l.accountId == accountId && !l.isCompleted)
        .fold<double>(0.0, (sum, l) => sum + l.currentMonthlyPayment);

    final transferNotifier = ref.read(transferProvider.notifier);
    final transferBalance = transferNotifier.getMonthlyTransferBalance(
      accountId,
    );

    return totalRevenues - totalExpenses - totalLoanPayments + transferBalance;
  }
}
