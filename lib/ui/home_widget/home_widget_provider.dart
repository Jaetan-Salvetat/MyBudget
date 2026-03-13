import 'package:mybudget/core/services/account_balance_data.dart';
import 'package:mybudget/core/services/home_widget_sync_service.dart';
import 'package:mybudget/core/services/upcoming_item_data.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/expenses/expense_queries.dart';
import 'package:mybudget/ui/loans/loan_queries.dart';
import 'package:mybudget/ui/revenues/revenue_queries.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_widget_provider.g.dart';

@Riverpod(keepAlive: true)
class HomeWidgetNotifier extends _$HomeWidgetNotifier {
  @override
  DateTime build() {
    _syncAll();
    return DateTime.now();
  }

  Future<void> _syncAll() async {
    try {
      await Future.wait([
        _syncMonthlySummary(),
        _syncAccountBalances(),
        _syncUpcomingPayments(),
      ]);
    } catch (_) {}
  }

  Future<void> _syncMonthlySummary() async {
    final expenses = ref.watch(monthlyExpensesProvider);
    final revenues = ref.watch(monthlyRevenuesProvider);
    final loanPayments = ref.watch(totalMonthlyLoanPaymentsProvider);
    final netBalance = revenues - (expenses + loanPayments);

    await HomeWidgetSyncService.syncMonthlySummary(
      netBalance: netBalance,
      monthlyRevenues: revenues,
      monthlyExpenses: expenses,
      totalMonthlyLoanPayments: loanPayments,
    );
  }

  Future<void> _syncAccountBalances() async {
    final accounts = ref.watch(accountProvider).value ?? [];
    final accountNotifier = ref.read(accountProvider.notifier);

    final balances = accounts.map((account) => AccountBalanceData(
      id: account.id,
      name: account.name,
      bank: account.bank,
      balance: accountNotifier.getAccountBalance(account.id),
    )).toList();

    await HomeWidgetSyncService.syncAccountBalances(balances);
  }

  Future<void> _syncUpcomingPayments() async {
    final now = DateTime.now();
    final items = <UpcomingItemData>[];

    final expenses = ref.watch(upcomingExpensesProvider);
    for (final expense in expenses) {
      items.add(UpcomingItemData(
        name: expense.name,
        amount: expense.amount,
        day: expense.date.day,
        type: 'expense',
      ));
    }

    final revenues = ref.watch(upcomingRevenuesProvider);
    for (final revenue in revenues) {
      items.add(UpcomingItemData(
        name: revenue.name,
        amount: revenue.amount,
        day: revenue.date.day,
        type: 'revenue',
      ));
    }

    final activeLoans = ref.watch(activeLoansProvider);
    for (final loan in activeLoans) {
      if (loan.dayOfMonth >= now.day) {
        items.add(UpcomingItemData(
          name: loan.name,
          amount: loan.currentMonthlyPayment,
          day: loan.dayOfMonth,
          type: 'loan',
        ));
      }
    }

    items.sort((a, b) => a.day.compareTo(b.day));

    await HomeWidgetSyncService.syncUpcomingPayments(items);
  }
}
