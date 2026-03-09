import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expense_queries.g.dart';

/// Total mensuel des dépenses (annuelles ramenées sur 12 mois).
@Riverpod(keepAlive: true)
double monthlyExpenses(Ref ref) {
  final expenses = ref.watch(expenseProvider).value ?? [];
  double total = 0.0;
  for (final expense in expenses) {
    if (expense.frequencyEnum == Frequency.monthly) {
      total += expense.amount;
    } else if (expense.frequencyEnum == Frequency.annual) {
      total += expense.amount / 12;
    }
  }
  return total;
}

/// Total annuel des dépenses (mensuelles × 12 + annuelles).
@Riverpod(keepAlive: true)
double annualExpenses(Ref ref) {
  final expenses = ref.watch(expenseProvider).value ?? [];
  double total = 0.0;
  for (final expense in expenses) {
    if (expense.frequencyEnum == Frequency.monthly) {
      total += expense.amount * 12;
    } else if (expense.frequencyEnum == Frequency.annual) {
      total += expense.amount;
    }
  }
  return total;
}

/// Dépenses dont l'échéance tombe à partir d'aujourd'hui dans le mois courant.
@Riverpod(keepAlive: true)
List<ExpenseModel> upcomingExpenses(Ref ref) {
  final expenses = ref.watch(expenseProvider).value ?? [];
  final now = DateTime.now();
  final upcoming = expenses.where((expense) {
    if (expense.frequencyEnum == Frequency.monthly) {
      return expense.date.day >= now.day;
    } else if (expense.frequencyEnum == Frequency.annual) {
      return expense.date.month == now.month && expense.date.day >= now.day;
    }
    return expense.date.year == now.year &&
        expense.date.month == now.month &&
        expense.date.day >= now.day;
  }).toList();
  upcoming.sort((a, b) => a.date.day.compareTo(b.date.day));
  return upcoming;
}

/// Dépenses agrégées par catégorie (Map<CategoryModel, montant>).
@Riverpod(keepAlive: true)
Map<CategoryModel, double> expensesByCategory(Ref ref) {
  final expenses = ref.watch(expenseProvider).value ?? [];
  final categoryRepo = ref.read(categoryRepositoryProvider);

  final Map<int, double> categoryTotals = {};
  for (final expense in expenses) {
    categoryTotals.update(
      expense.categoryId,
      (value) => value + expense.amount,
      ifAbsent: () => expense.amount,
    );
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
