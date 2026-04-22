import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/transfers/transfers_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'accounts_provider.g.dart';

@Riverpod(keepAlive: true)
class AccountNotifier extends _$AccountNotifier {
  @override
  Future<List<AccountModel>> build() async {
    ref.watch(expenseProvider);
    ref.watch(revenueProvider);
    ref.watch(loanProvider);
    ref.watch(transferProvider);

    final repo = ref.watch(accountRepositoryProvider);
    return repo.getAll();
  }

  Future<void> addAccount(AccountModel account) async {
    try {
      final repo = ref.read(accountRepositoryProvider);
      repo.add(account);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAccount(AccountModel account) async {
    try {
      final repo = ref.read(accountRepositoryProvider);
      repo.update(account);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAccount(int id) async {
    try {
      final repo = ref.read(accountRepositoryProvider);
      repo.delete(id);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
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
    final transferBalance = transferNotifier.getMonthlyTransferBalance(accountId);

    return totalRevenues - totalExpenses - totalLoanPayments + transferBalance;
  }

}
