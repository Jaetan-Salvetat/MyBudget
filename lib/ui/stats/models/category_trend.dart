import 'package:material_ui/material_ui.dart';

class CategoryTrend {
  const CategoryTrend({
    required this.groupKey,
    required this.label,
    required this.color,
    required this.amount,
    required this.previousAmount,
  });
  final String groupKey;
  final String label;
  final Color color;
  final double amount;
  final double previousAmount;

  double get delta => amount - previousAmount;

  bool get isNew => previousAmount <= 0;
}
