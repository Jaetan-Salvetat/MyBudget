import 'package:flutter/material.dart';
import 'package:mybudget/ui/accounts/account_queries.dart';
import 'package:mybudget/ui/dashboard/models/category_expense_summary.dart';
import 'package:mybudget/ui/expenses/expense_queries.dart';
import 'package:mybudget/ui/loans/loan_queries.dart';
import 'package:mybudget/ui/revenues/revenue_queries.dart';
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
  final List<CategoryExpenseSummary> categorySummaries;

  const DashboardState({
    required this.netCashFlow,
    required this.savingsRate,
    required this.totalLoanAmount,
    required this.monthlyExpenses,
    required this.monthlyRevenues,
    required this.totalMonthlyLoanPayments,
    required this.totalExpenses,
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
      categorySummaries: summaries,
    );
  }
}
