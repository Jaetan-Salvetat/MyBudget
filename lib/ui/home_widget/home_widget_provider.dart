import 'package:flutter/foundation.dart';
import 'package:mybudget/data/provider/accounts_provider.dart';
import 'package:mybudget/data/provider/loan_queries.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/service/account_balance_data.dart';
import 'package:mybudget/data/service/home_widget_sync_service.dart';
import 'package:mybudget/data/service/upcoming_item_data.dart';
import 'package:mybudget/ui/shared/expense_queries.dart';
import 'package:mybudget/ui/shared/revenue_queries.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_widget_provider.g.dart';

@Riverpod(keepAlive: true)
class HomeWidgetNotifier extends _$HomeWidgetNotifier {
  @override
  DateTime build() {
    _syncAll();
    return ref.watch(clockProvider)();
  }

  Future<void> _syncAll() async {
    try {
      await Future.wait([
        _syncMonthlySummary(),
        _syncAccountBalances(),
        _syncUpcomingPayments(),
      ]);
    } catch (error, stackTrace) {
      debugPrint('Synchronisation du widget impossible : $error\n$stackTrace');
    }
  }

  Future<void> _syncMonthlySummary() async {
    final expenses = ref.watch(currentMonthExpensesProvider);
    final revenues = ref.watch(currentMonthRevenuesProvider);
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
    final accounts = ref.watch(accountProvider);
    final accountNotifier = ref.read(accountProvider.notifier);

    final balances = accounts
        .map(
          (account) => AccountBalanceData(
            id: account.id,
            name: account.name,
            bank: account.bank,
            balance: accountNotifier.getAccountBalance(account.id),
          ),
        )
        .toList();

    await HomeWidgetSyncService.syncAccountBalances(balances);
  }

  Future<void> _syncUpcomingPayments() async {
    final now = ref.read(clockProvider)();
    final items = <UpcomingItemData>[];

    final expenses = ref.watch(upcomingExpensesProvider);
    for (final expense in expenses) {
      items.add(
        UpcomingItemData(
          name: expense.name,
          amount: expense.amount,
          day: expense.startDate.day,
          type: 'expense',
        ),
      );
    }

    final revenues = ref.watch(upcomingRevenuesProvider);
    for (final revenue in revenues) {
      items.add(
        UpcomingItemData(
          name: revenue.name,
          amount: revenue.amount,
          day: revenue.startDate.day,
          type: 'revenue',
        ),
      );
    }

    final activeLoans = ref.watch(activeLoansProvider);
    for (final loan in activeLoans) {
      if (loan.dayOfMonth >= now.day) {
        items.add(
          UpcomingItemData(
            name: loan.name,
            amount: loan.currentMonthlyPayment,
            day: loan.dayOfMonth,
            type: 'loan',
          ),
        );
      }
    }

    items.sort((a, b) => a.day.compareTo(b.day));

    await HomeWidgetSyncService.syncUpcomingPayments(items);
  }
}
