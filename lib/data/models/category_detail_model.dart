import 'package:flutter/material.dart';
import 'package:mybudget/data/models/expense_model.dart';

class CategoryDetailModel {
  final int categoryId;
  final String name;
  final String icon;
  final Color color;
  final double totalAmount;
  final double percentageOfTotal;
  final List<ExpenseModel> expenses;
  final double averageExpense;
  final int mostFrequentDay;
  final Map<int, double> accountUsage;

  CategoryDetailModel({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.totalAmount,
    required this.percentageOfTotal,
    required this.expenses,
    required this.averageExpense,
    required this.mostFrequentDay,
    required this.accountUsage,
  });
}
