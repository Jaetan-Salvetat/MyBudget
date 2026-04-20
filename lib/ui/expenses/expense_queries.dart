import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expense_queries.g.dart';

double _expenseAmountForMonth(ExpenseModel expense, DateTime month) {
  switch (expense.frequencyEnum) {
    case Frequency.monthly:
      return expense.amount;
    case Frequency.annual:
      return expense.date.month == month.month ? expense.amount : 0.0;
    case Frequency.oneTime:
      return expense.date.year == month.year &&
              expense.date.month == month.month
          ? expense.amount
          : 0.0;
  }
}

@Riverpod(keepAlive: true)
double monthlyExpenses(Ref ref) {
  final expenses = ref.watch(expenseProvider).value ?? [];
  final selectedMonth = ref.watch(selectedMonthProvider);
  double total = 0.0;
  for (final expense in expenses) {
    total += _expenseAmountForMonth(expense, selectedMonth);
  }
  return total;
}

@Riverpod(keepAlive: true)
double currentMonthExpenses(Ref ref) {
  final expenses = ref.watch(expenseProvider).value ?? [];
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
        if (expense.date.year == selectedMonth.year) {
          total += expense.amount;
        }
    }
  }
  return total;
}

@Riverpod(keepAlive: true)
List<ExpenseModel> upcomingExpenses(Ref ref) {
  final expenses = ref.watch(expenseProvider).value ?? [];
  final now = DateTime.now();
  final upcoming = expenses.where((expense) {
    switch (expense.frequencyEnum) {
      case Frequency.monthly:
        return expense.date.day >= now.day;
      case Frequency.annual:
        return expense.date.month == now.month && expense.date.day >= now.day;
      case Frequency.oneTime:
        final expenseDate = DateTime(
          expense.date.year,
          expense.date.month,
          expense.date.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        return !expenseDate.isBefore(today);
    }
  }).toList();
  upcoming.sort((a, b) => a.date.day.compareTo(b.date.day));
  return upcoming;
}

@Riverpod(keepAlive: true)
Map<CategoryModel, double> expensesByCategory(Ref ref) {
  final expenses = ref.watch(expenseProvider).value ?? [];
  final selectedMonth = ref.watch(selectedMonthProvider);
  final categoryRepo = ref.read(categoryRepositoryProvider);

  final Map<int, double> categoryTotals = {};
  for (final expense in expenses) {
    final amount = _expenseAmountForMonth(expense, selectedMonth);
    if (amount > 0) {
      categoryTotals.update(
        expense.categoryId,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
    }
  }

  final Map<CategoryModel, double> result = {};
  for (final entry in categoryTotals.entries) {
    final category = categoryRepo.get(entry.key);
    if (category != null) {
      result[category] = entry.value;
    }
  }
  return result;
}
