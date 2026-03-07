import 'package:flutter/material.dart';

class CategoryExpenseSummary {
  final String categoryName;
  final double amount;
  final double percentage;
  final Color color;
  final IconData icon;
  final int categoryId;

  CategoryExpenseSummary({
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.icon,
    required this.categoryId,
  });
}
