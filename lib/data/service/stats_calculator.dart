import 'package:mybudget/core/contracts/filterable_transaction.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/rules/recurrence_rules.dart';
import 'package:mybudget/core/values/loan.dart';
import 'package:mybudget/core/values/monthly_flow.dart';
import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/model/revenue_model.dart';
import 'package:mybudget/data/service/category_display_resolver.dart';

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
  const StatsCalculator({
    required this.expenses,
    required this.revenues,
    required this.loans,
    required this.resolver,
  });
  static const String loanGroupKey = 'finance';

  final List<ExpenseModel> expenses;
  final List<RevenueModel> revenues;
  final List<Loan> loans;
  final CategoryDisplayResolver? resolver;

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

  List<MonthlyFlow> flowsSinceFirstActivity(List<DateTime> months) {
    final flows = flowsOver(months);
    final firstActive = flows.indexWhere((flow) => !flow.isEmpty);
    return firstActive <= 0 ? flows : flows.sublist(firstActive);
  }

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
    double total = _recurringTotalOver(expenses, months);
    for (final month in months) {
      total += _loanPaymentsIn(month);
    }
    return total;
  }

  double recurringIncomesOver(List<DateTime> months) =>
      _recurringTotalOver(revenues, months);

  double _recurringTotalOver(
    Iterable<FilterableTransaction> transactions,
    List<DateTime> months,
  ) {
    double total = 0;
    for (final month in months) {
      for (final transaction in transactions) {
        if (transaction.frequencyEnum == Frequency.oneTime) continue;
        if (!occursIn(transaction, month)) continue;
        total += transaction.amount;
      }
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
