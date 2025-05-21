import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/core/controllers/category_controller.dart';
import 'package:mybudget/core/controllers/expense_controller.dart';
import 'package:mybudget/core/controllers/settings_controller.dart';
import 'package:mybudget/data/models/category_model.dart';

extension ExpenseControllerExtension on ExpenseController {
  List<CategoryExpenseSummary> getExpensesByCategory({int? limit}) {
    if (expenses.isEmpty) return [];

    final settingsController = Get.find<SettingsController>();
    final calculationMode =
        settingsController.annualExpenseCalculationMode.value;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final categoryController = Get.find<CategoryController>();
    final Map<int, double> categoryAmounts = {};
    double totalAmount = 0.0;

    for (final expense in expenses) {
      final isCurrentMonth =
          expense.date.isAtSameMomentAs(startOfMonth) ||
          expense.date.isAtSameMomentAs(endOfMonth) ||
          (expense.date.isAfter(startOfMonth) &&
              expense.date.isBefore(endOfMonth));

      if (expense.frequency == 'Mensuel' && isCurrentMonth) {
        categoryAmounts[expense.categoryId] =
            (categoryAmounts[expense.categoryId] ?? 0.0) + expense.amount;
        totalAmount += expense.amount;
      } else if (expense.frequency == 'Annuel') {
        switch (calculationMode) {
          case AnnualExpenseCalculationMode.monthlyAmortized:
            categoryAmounts[expense.categoryId] =
                (categoryAmounts[expense.categoryId] ?? 0.0) +
                (expense.amount / 12);
            totalAmount += expense.amount / 12;
            break;
          case AnnualExpenseCalculationMode.dateBasedOnly:
            if (isCurrentMonth) {
              categoryAmounts[expense.categoryId] =
                  (categoryAmounts[expense.categoryId] ?? 0.0) + expense.amount;
              totalAmount += expense.amount;
            }
            break;
        }
      }
    }

    final List<CategoryExpenseSummary> result = [];

    for (final categoryId in categoryAmounts.keys) {
      final category = categoryController.categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => CategoryModel()..name = 'Autre',
      );

      result.add(
        CategoryExpenseSummary(
          categoryId: categoryId,
          categoryName: category.name,
          icon: _getCategoryIconData(category.icon),
          amount: categoryAmounts[categoryId] ?? 0.0,
          percentage:
              totalAmount > 0
                  ? (categoryAmounts[categoryId] ?? 0.0) / totalAmount
                  : 0.0,
          color: _getCategoryColor(category.name),
        ),
      );
    }

    result.sort((a, b) => b.amount.compareTo(a.amount));

    if (limit == null || result.length <= limit) return result;

    final topCategories = result.sublist(0, limit - 1);
    final otherAmount = result
        .sublist(limit - 1)
        .fold<double>(0.0, (sum, item) => sum + item.amount);

    if (otherAmount > 0) {
      topCategories.add(
        CategoryExpenseSummary(
          categoryId: -1,
          categoryName: 'Autres',
          icon: Icons.more_horiz,
          amount: otherAmount,
          percentage: totalAmount > 0 ? otherAmount / totalAmount : 0.0,
          color: Colors.blueGrey,
        ),
      );
    }

    return topCategories;
  }

  IconData _getCategoryIconData(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'medical_services':
        return Icons.medical_services;
      case 'checkroom':
        return Icons.checkroom;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'alimentation':
        return Colors.green;
      case 'transport':
        return Colors.blue;
      case 'logement':
        return Colors.orange;
      case 'loisirs':
        return Colors.purple;
      case 'santé':
        return Colors.red;
      case 'vêtements':
        return Colors.pink;
      default:
        return Colors.blueGrey;
    }
  }

  List<dynamic> getUpcomingPayments({int limit = 5}) {
    if (expenses.isEmpty) return [];

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final upcomingExpenses =
        expenses
            .where(
              (expense) =>
                  expense.date.isAfter(startOfDay) ||
                  expense.date.isAtSameMomentAs(startOfDay),
            )
            .toList();

    upcomingExpenses.sort((a, b) => a.date.compareTo(b.date));

    return upcomingExpenses.take(limit).toList();
  }
}

class CategoryExpenseSummary {
  final int categoryId;
  final String categoryName;
  final IconData icon;
  final double amount;
  final double percentage;
  final Color color;

  CategoryExpenseSummary({
    required this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}
