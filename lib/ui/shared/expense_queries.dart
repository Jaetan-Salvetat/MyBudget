import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/rules/recurrence_rules.dart';
import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/model/transaction_event_model.dart';
import 'package:mybudget/data/provider/category_override_provider.dart';
import 'package:mybudget/data/provider/expenses_provider.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/service/stats_calculator.dart';
import 'package:mybudget/ui/shared/selected_month_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expense_queries.g.dart';

@Riverpod(keepAlive: true)
List<ExpenseModel> expenseHistory(Ref ref) {
  final open = ref.watch(expenseProvider).value ?? const <ExpenseModel>[];
  final closed = ref.watch(expenseRepositoryProvider).getClosed();
  return [...open, ...closed];
}

@Riverpod(keepAlive: true)
List<ExpenseModel> monthExpenses(Ref ref) {
  final expenses = ref.watch(expenseHistoryProvider);
  final month = ref.watch(selectedMonthProvider);

  return [
    for (final expense in expenses)
      if (occursIn(expense, month)) _datedOn(expense, month),
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

@Riverpod(keepAlive: true)
double monthlyExpenses(Ref ref) {
  return totalInMonth(
    ref.watch(expenseHistoryProvider),
    ref.watch(selectedMonthProvider),
  );
}

@Riverpod(keepAlive: true)
double currentMonthExpenses(Ref ref) {
  final now = ref.watch(clockProvider)();
  return totalInMonth(
    ref.watch(expenseHistoryProvider),
    DateTime(now.year, now.month),
  );
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
  final now = ref.watch(clockProvider)();
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

@Riverpod(keepAlive: true)
Map<String, double> expensesByGroup(Ref ref) {
  final expenses = ref.watch(expenseHistoryProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final resolver = ref.watch(categoryDisplayResolverProvider).value;
  if (resolver == null) return const {};

  return groupTotalsIn(expenses, selectedMonth, resolver);
}

@Riverpod(keepAlive: true)
List<TransactionEventModel> expenseEvents(Ref ref, int rootId) {
  ref.watch(expenseProvider);
  return ref
      .watch(transactionEventRepositoryProvider)
      .getForRoot(rootId, TransactionType.expense);
}
