import 'package:flutter/material.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/ui/accounts/account_queries.dart';
import 'package:mybudget/ui/dashboard/models/category_expense_summary.dart';
import 'package:mybudget/ui/expenses/expense_queries.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/loans/loan_queries.dart';
import 'package:mybudget/ui/revenues/revenue_queries.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/utils/history_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_provider.g.dart';

class DashboardState {
  final double netCashFlow;
  final double savingsRate;
  final double totalLoanAmount;
  final double monthlyExpenses;
  final double monthlyRevenues;
  final double totalMonthlyLoanPayments;
  final double totalExpenses;
  final double recurringExpenses;
  final double oneTimeExpenses;
  final double recurringRevenues;
  final double oneTimeRevenues;
  final List<CategoryExpenseSummary> categorySummaries;

  const DashboardState({
    required this.netCashFlow,
    required this.savingsRate,
    required this.totalLoanAmount,
    required this.monthlyExpenses,
    required this.monthlyRevenues,
    required this.totalMonthlyLoanPayments,
    required this.totalExpenses,
    required this.recurringExpenses,
    required this.oneTimeExpenses,
    required this.recurringRevenues,
    required this.oneTimeRevenues,
    required this.categorySummaries,
  });
}

@Riverpod(keepAlive: true)
class DashboardNotifier extends _$DashboardNotifier {
  @override
  DashboardState build() {
    final monthlyExpenses = ref.watch(monthlyExpensesProvider);
    final totalMonthlyLoanPayments = ref.watch(totalMonthlyLoanPaymentsProvider);
    final totalExpenses = monthlyExpenses + totalMonthlyLoanPayments;
    final selectedMonth = ref.watch(selectedMonthProvider);

    double recurringExp = 0.0;
    double oneTimeExp = 0.0;
    final expenses = ref.watch(expenseProvider).value ?? [];
    for (final expense in expenses) {
      if (!isActiveForMonth(expense.startDate, expense.endDate, selectedMonth)) {
        continue;
      }
      switch (expense.frequencyEnum) {
        case Frequency.monthly:
          recurringExp += expense.amount;
        case Frequency.annual:
          if (expense.startDate.month == selectedMonth.month) {
            recurringExp += expense.amount;
          }
        case Frequency.oneTime:
          if (expense.startDate.year == selectedMonth.year &&
              expense.startDate.month == selectedMonth.month) {
            oneTimeExp += expense.amount;
          }
      }
    }

    double recurringRev = 0.0;
    double oneTimeRev = 0.0;
    final revenues = ref.watch(revenueProvider).value ?? [];
    for (final revenue in revenues) {
      if (!isActiveForMonth(revenue.startDate, revenue.endDate, selectedMonth)) {
        continue;
      }
      switch (revenue.frequencyEnum) {
        case Frequency.monthly:
          recurringRev += revenue.amount;
        case Frequency.annual:
          if (revenue.startDate.month == selectedMonth.month) {
            recurringRev += revenue.amount;
          }
        case Frequency.oneTime:
          if (revenue.startDate.year == selectedMonth.year &&
              revenue.startDate.month == selectedMonth.month) {
            oneTimeRev += revenue.amount;
          }
      }
    }

    final categoryExpensesMap = ref.watch(expensesByCategoryProvider);
    final List<CategoryExpenseSummary> summaries = [];

    if (totalExpenses > 0) {
      categoryExpensesMap.forEach((category, amount) {
        summaries.add(
          CategoryExpenseSummary(
            categoryName: category.name,
            amount: amount,
            percentage: amount / totalExpenses,
            color: Color(category.color),
            icon: category.getIconData(),
            categoryId: category.id,
          ),
        );
      });
      summaries.sort((a, b) => b.amount.compareTo(a.amount));
    }

    return DashboardState(
      netCashFlow: ref.watch(netCashFlowProvider),
      savingsRate: ref.watch(savingsRateProvider),
      totalLoanAmount: ref.watch(totalRemainingLoanAmountProvider),
      monthlyExpenses: monthlyExpenses,
      monthlyRevenues: ref.watch(monthlyRevenuesProvider),
      totalMonthlyLoanPayments: totalMonthlyLoanPayments,
      totalExpenses: totalExpenses,
      recurringExpenses: recurringExp,
      oneTimeExpenses: oneTimeExp,
      recurringRevenues: recurringRev,
      oneTimeRevenues: oneTimeRev,
      categorySummaries: summaries,
    );
  }
}
