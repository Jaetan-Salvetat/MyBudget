import 'package:material_ui/material_ui.dart';

class CategorySlice {
  final String groupKey;
  final String label;
  final Color color;
  final double amount;
  final double share;

  const CategorySlice({
    required this.groupKey,
    required this.label,
    required this.color,
    required this.amount,
    required this.share,
  });
}
