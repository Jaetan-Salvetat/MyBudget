import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/utils/history_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expense_queries.g.dart';

/// Every rule ever recorded, the closed ones included. Editing or deleting a
/// recurring expense closes its row and opens another : reading only the open
/// ones would erase the months the closed one was actually paid in.
@Riverpod(keepAlive: true)
List<ExpenseModel> expenseHistory(Ref ref) {
  final open = ref.watch(expenseProvider).value ?? const <ExpenseModel>[];
  final closed = ref.watch(expenseRepositoryProvider).getClosed();
  return [...open, ...closed];
}

/// The rules that fall on the selected month, each dated on the day it lands
/// there. The list drawn on screen and the total announced above it read the
/// same rule, so one can never say something the other denies.
@Riverpod(keepAlive: true)
List<ExpenseModel> monthExpenses(Ref ref) {
  final expenses = ref.watch(expenseHistoryProvider);
  final month = ref.watch(selectedMonthProvider);

  return [
    for (final expense in expenses)
      if (occursInMonth(
        expense.startDate,
        expense.endDate,
        expense.frequencyEnum,
        month,
      ))
        _datedOn(expense, month),
  ];
}

ExpenseModel _datedOn(ExpenseModel expense, DateTime month) {
  final landing = dayInMonthOf(expense.startDate, expense.frequencyEnum, month);
  if (landing == expense.startDate) return expense;
  return expense.copyWith(startDate: landing);
}

@Riverpod(keepAlive: true)
List<ExpenseModel> activeExpenses(Ref ref) {
  final expenses = ref.watch(expenseProvider).value ?? [];
  return expenses.where((e) => e.endDate == null).toList();
}

double _expenseAmountForMonth(ExpenseModel expense, DateTime month) {
  final falls = occursInMonth(
    expense.startDate,
    expense.endDate,
    expense.frequencyEnum,
    month,
  );
  return falls ? expense.amount : 0.0;
}

@Riverpod(keepAlive: true)
double monthlyExpenses(Ref ref) {
  final expenses = ref.watch(expenseHistoryProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  double total = 0.0;
  for (final expense in expenses) {
    total += _expenseAmountForMonth(expense, selectedMonth);
  }
  return total;
}

@Riverpod(keepAlive: true)
double currentMonthExpenses(Ref ref) {
  final expenses = ref.watch(expenseHistoryProvider);
  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month);
  double total = 0.0;
  for (final expense in expenses) {
    total += _expenseAmountForMonth(expense, currentMonth);
  }
  return total;
}

@Riverpod(keepAlive: true)
double annualExpenses(Ref ref) {
  final expenses = ref.watch(expenseProvider).value ?? [];
  final selectedMonth = ref.watch(selectedMonthProvider);
  double total = 0.0;
  for (final expense in expenses) {
    switch (expense.frequencyEnum) {
      case Frequency.monthly:
        total += expense.amount * 12;
      case Frequency.annual:
        total += expense.amount;
      case Frequency.oneTime:
        if (expense.startDate.year == selectedMonth.year) {
          total += expense.amount;
        }
    }
  }
  return total;
}

@Riverpod(keepAlive: true)
List<ExpenseModel> upcomingExpenses(Ref ref) {
  final expenses = ref.watch(activeExpensesProvider);
  final now = DateTime.now();
  final upcoming = expenses.where((expense) {
    switch (expense.frequencyEnum) {
      case Frequency.monthly:
        return expense.startDate.day >= now.day;
      case Frequency.annual:
        return expense.startDate.month == now.month &&
            expense.startDate.day >= now.day;
      case Frequency.oneTime:
        final expenseDate = DateTime(
          expense.startDate.year,
          expense.startDate.month,
          expense.startDate.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        return !expenseDate.isBefore(today);
    }
  }).toList();
  upcoming.sort((a, b) => a.startDate.day.compareTo(b.startDate.day));
  return upcoming;
}

/// Monthly totals per taxonomy group key, for the dashboard breakdown.
///
/// Aggregation happens at group level: 11 expense groups stay readable where 59
/// leaves would not.
@Riverpod(keepAlive: true)
Map<String, double> expensesByGroup(Ref ref) {
  final expenses = ref.watch(expenseHistoryProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final resolver = ref.watch(categoryDisplayResolverProvider).value;
  if (resolver == null) return const {};

  final totals = <String, double>{};
  for (final expense in expenses) {
    final amount = _expenseAmountForMonth(expense, selectedMonth);
    if (amount <= 0) continue;
    final groupKey = resolver.groupKeyOrUncategorized(expense.categorySlug);
    totals.update(groupKey, (value) => value + amount, ifAbsent: () => amount);
  }
  return totals;
}
