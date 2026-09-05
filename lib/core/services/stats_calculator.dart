import 'package:mybudget/core/entities/filterable_transaction.dart';
import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/core/entities/monthly_flow.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/utils/history_utils.dart';

Map<String, double> groupTotalsIn(
  Iterable<FilterableTransaction> transactions,
  DateTime month,
  CategoryDisplayResolver resolver,
) {
  final totals = <String, double>{};
  for (final transaction in transactions) {
    if (!occursIn(transaction, month)) continue;
    final groupKey = resolver.groupKeyOrUncategorized(transaction.categorySlug);
    totals.update(
      groupKey,
      (value) => value + transaction.amount,
      ifAbsent: () => transaction.amount,
    );
  }
  return totals;
}

class StatsCalculator {
  static const String loanGroupKey = 'finance';

  final List<ExpenseModel> expenses;
  final List<RevenueModel> revenues;
  final List<Loan> loans;
  final CategoryDisplayResolver? resolver;

  const StatsCalculator({
    required this.expenses,
    required this.revenues,
    required this.loans,
    required this.resolver,
  });

  static List<DateTime> monthsEndingAt(DateTime anchor, int count) => [
    for (var offset = count - 1; offset >= 0; offset--)
      DateTime(anchor.year, anchor.month - offset),
  ];

  List<MonthlyFlow> flowsOver(List<DateTime> months) => [
    for (final month in months)
      MonthlyFlow(
        month: month,
        incomes: totalInMonth(revenues, month),
        expenses: totalInMonth(expenses, month) + _loanPaymentsIn(month),
      ),
  ];

  Map<String, double> expensesByGroupOver(List<DateTime> months) {
    final resolver = this.resolver;
    if (resolver == null) return const {};

    final totals = <String, double>{};
    for (final month in months) {
      groupTotalsIn(expenses, month, resolver).forEach((groupKey, amount) {
        totals.update(
          groupKey,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      });

      final loanPayments = _loanPaymentsIn(month);
      if (loanPayments <= 0) continue;
      totals.update(
        loanGroupKey,
        (value) => value + loanPayments,
        ifAbsent: () => loanPayments,
      );
    }
    return totals;
  }

  double recurringExpensesOver(List<DateTime> months) {
    double total = 0;
    for (final month in months) {
      for (final expense in expenses) {
        if (expense.frequencyEnum == Frequency.oneTime) continue;
        if (!occursIn(expense, month)) continue;
        total += expense.amount;
      }
      total += _loanPaymentsIn(month);
    }
    return total;
  }

  DateTime? earliestMonth() {
    DateTime? earliest;
    void consider(DateTime candidate) {
      final month = DateTime(candidate.year, candidate.month);
      if (earliest == null || month.isBefore(earliest!)) earliest = month;
    }

    for (final expense in expenses) {
      consider(expense.startDate);
    }
    for (final revenue in revenues) {
      consider(revenue.startDate);
    }
    for (final loan in loans) {
      consider(loan.startDate);
    }
    return earliest;
  }

  double _loanPaymentsIn(DateTime month) =>
      loans.fold(0.0, (sum, loan) => sum + loan.paymentsInMonth(month));
}
