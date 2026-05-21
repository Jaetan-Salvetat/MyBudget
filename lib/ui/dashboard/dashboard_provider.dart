import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/accounts/account_queries.dart';
import 'package:mybudget/ui/dashboard/models/category_expense_summary.dart';
import 'package:mybudget/ui/dashboard/models/loan_progress_summary.dart';
import 'package:mybudget/ui/dashboard/models/upcoming_movement.dart';
import 'package:mybudget/ui/expenses/expense_queries.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/loans/loan_queries.dart';
import 'package:mybudget/ui/revenues/revenue_queries.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/settings/beneficiary_provider.dart';
import 'package:mybudget/ui/settings/category_provider.dart';
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
  final List<UpcomingMovement> upcomingMovements;
  final LoanProgressSummary loanProgress;

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
    required this.upcomingMovements,
    required this.loanProgress,
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

    final expenses = ref.watch(expenseProvider).value ?? [];
    final revenues = ref.watch(revenueProvider).value ?? [];
    final categories = ref.watch(categoryProvider).value ?? [];
    final beneficiaries = ref.watch(beneficiaryProvider).value ?? [];

    final categoryById = {for (final c in categories) c.id: c};
    final beneficiaryById = {for (final b in beneficiaries) b.id: b};

    final flows = _computeFlows(expenses, revenues, selectedMonth);

    final categoryExpensesMap = ref.watch(expensesByCategoryProvider);
    final summaries = _buildCategorySummaries(categoryExpensesMap, totalExpenses);

    final upcoming = _buildUpcomingMovements(
      expenses: expenses,
      revenues: revenues,
      selectedMonth: selectedMonth,
      categoryById: categoryById,
      beneficiaryById: beneficiaryById,
    );

    final loanProgress = LoanProgressSummary(
      totalBorrowed: ref.watch(activeLoansProvider).fold(0.0, (s, l) => s + l.amount),
      totalRepaid: ref.watch(activeLoansProvider).fold(0.0, (s, l) => s + (l.amount - l.remainingCapital)),
      totalRemaining: ref.watch(totalRemainingLoanAmountProvider),
      monthlyPayments: totalMonthlyLoanPayments,
      activeCount: ref.watch(activeLoansProvider).length,
      progressPercent: ref.watch(overallLoanProgressPercentageProvider),
    );

    return DashboardState(
      netCashFlow: ref.watch(netCashFlowProvider),
      savingsRate: ref.watch(savingsRateProvider),
      totalLoanAmount: ref.watch(totalRemainingLoanAmountProvider),
      monthlyExpenses: monthlyExpenses,
      monthlyRevenues: ref.watch(monthlyRevenuesProvider),
      totalMonthlyLoanPayments: totalMonthlyLoanPayments,
      totalExpenses: totalExpenses,
      recurringExpenses: flows.recurringExpenses,
      oneTimeExpenses: flows.oneTimeExpenses,
      recurringRevenues: flows.recurringRevenues,
      oneTimeRevenues: flows.oneTimeRevenues,
      categorySummaries: summaries,
      upcomingMovements: upcoming,
      loanProgress: loanProgress,
    );
  }

  _MonthlyFlows _computeFlows(
    List<ExpenseModel> expenses,
    List<RevenueModel> revenues,
    DateTime selectedMonth,
  ) {
    double recurringExp = 0;
    double oneTimeExp = 0;
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

    double recurringRev = 0;
    double oneTimeRev = 0;
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

    return _MonthlyFlows(
      recurringExpenses: recurringExp,
      oneTimeExpenses: oneTimeExp,
      recurringRevenues: recurringRev,
      oneTimeRevenues: oneTimeRev,
    );
  }

  List<CategoryExpenseSummary> _buildCategorySummaries(
    Map<CategoryModel, double> categoryExpensesMap,
    double totalExpenses,
  ) {
    if (totalExpenses <= 0) return const [];
    final summaries = <CategoryExpenseSummary>[];
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
    return summaries;
  }

  List<UpcomingMovement> _buildUpcomingMovements({
    required List<ExpenseModel> expenses,
    required List<RevenueModel> revenues,
    required DateTime selectedMonth,
    required Map<int, CategoryModel> categoryById,
    required Map<int, Beneficiary> beneficiaryById,
  }) {
    final now = DateTime.now();
    final viewingCurrentMonth =
        now.year == selectedMonth.year && now.month == selectedMonth.month;
    final todayDay = viewingCurrentMonth ? now.day : 0;

    final movements = <UpcomingMovement>[];

    for (final expense in expenses) {
      if (!isActiveForMonth(expense.startDate, expense.endDate, selectedMonth)) {
        continue;
      }
      final day = _movementDay(expense.frequencyEnum, expense.startDate, selectedMonth);
      if (day == null || day <= todayDay) continue;
      final category = categoryById[expense.categoryId];
      movements.add(UpcomingMovement(
        id: 'e${expense.id}',
        name: expense.name,
        amount: expense.amount,
        date: DateTime(selectedMonth.year, selectedMonth.month, day),
        direction: MovementDirection.outgoing,
        icon: category?.getIconData() ?? Symbols.category_rounded,
        color: category != null ? Color(category.color) : Colors.grey,
        payee: _beneficiaryName(beneficiaryById, expense.beneficiaryId),
      ));
    }

    for (final revenue in revenues) {
      if (!isActiveForMonth(revenue.startDate, revenue.endDate, selectedMonth)) {
        continue;
      }
      final day = _movementDay(revenue.frequencyEnum, revenue.startDate, selectedMonth);
      if (day == null || day <= todayDay) continue;
      movements.add(UpcomingMovement(
        id: 'r${revenue.id}',
        name: revenue.name,
        amount: revenue.amount,
        date: DateTime(selectedMonth.year, selectedMonth.month, day),
        direction: MovementDirection.incoming,
        icon: Symbols.savings_rounded,
        color: Colors.green,
        payee: _beneficiaryName(beneficiaryById, revenue.beneficiaryId),
      ));
    }

    movements.sort((a, b) => a.date.compareTo(b.date));
    return movements;
  }

  int? _movementDay(Frequency frequency, DateTime startDate, DateTime selectedMonth) {
    switch (frequency) {
      case Frequency.monthly:
        return startDate.day;
      case Frequency.annual:
        return startDate.month == selectedMonth.month ? startDate.day : null;
      case Frequency.oneTime:
        return null;
    }
  }

  String? _beneficiaryName(Map<int, Beneficiary> map, int? id) {
    if (id == null) return null;
    return map[id]?.name;
  }
}

class _MonthlyFlows {
  final double recurringExpenses;
  final double oneTimeExpenses;
  final double recurringRevenues;
  final double oneTimeRevenues;

  const _MonthlyFlows({
    required this.recurringExpenses,
    required this.oneTimeExpenses,
    required this.recurringRevenues,
    required this.oneTimeRevenues,
  });
}
