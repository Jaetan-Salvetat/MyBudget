import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/core/controllers/expense_controller.dart';
import 'package:mybudget/data/models/category_model.dart';
import 'package:mybudget/data/models/expense_model.dart';

extension CategoryExtension on CategoryModel {
  Color get categoryColor {
    return switch (name.toLowerCase()) {
      'alimentation' => Colors.green,
      'transport' => Colors.blue,
      'logement' => Colors.orange,
      'loisirs' => Colors.purple,
      'santé' => Colors.red,
      'vêtements' => Colors.pink,
      _ => Colors.blueGrey,
    };
  }

  List<ExpenseModel> getCategoryExpenses() {
    final expenseController = Get.find<ExpenseController>();
    final allExpenses = expenseController.expenses;
    return allExpenses.where((expense) => expense.categoryId == id).toList();
  }

  double getTotalAmount() {
    final categoryExpenses = getCategoryExpenses();
    return categoryExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double getPercentageOfTotal() {
    final expenseController = Get.find<ExpenseController>();
    final totalExpenseAmount = expenseController.getTotalExpenses();
    final categoryTotal = getTotalAmount();
    return totalExpenseAmount > 0 ? (categoryTotal / totalExpenseAmount) : 0.0;
  }

  Map<int, double> getAccountUsage() {
    final categoryExpenses = getCategoryExpenses();
    Map<int, double> accountUsage = {};
    
    for (var expense in categoryExpenses) {
      final accountId = expense.accountId;
      accountUsage[accountId] = (accountUsage[accountId] ?? 0.0) + expense.amount;
    }
    
    return accountUsage;
  }

  int getMostFrequentDay() {
    final categoryExpenses = getCategoryExpenses();
    Map<int, int> dayFrequency = {};
    
    for (var expense in categoryExpenses) {
      final day = expense.date.day;
      dayFrequency[day] = (dayFrequency[day] ?? 0) + 1;
    }
    
    if (dayFrequency.isEmpty) return 1;
    
    return dayFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  double getAverageExpenseAmount() {
    final categoryExpenses = getCategoryExpenses();
    final categoryTotal = getTotalAmount();
    
    return categoryExpenses.isNotEmpty 
        ? categoryTotal / categoryExpenses.length 
        : 0.0;
  }
}
