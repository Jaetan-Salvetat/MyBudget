import 'package:mybudget/core/enums/transaction_type.dart';

class CategoryDisplay {
  const CategoryDisplay({
    required this.slug,
    required this.label,
    required this.icon,
    required this.color,
    required this.groupKey,
    required this.groupLabel,
    required this.type,
  });
  final String slug;
  final String label;
  final String icon;
  final int color;
  final String groupKey;
  final String groupLabel;
  final TransactionType type;

  bool get isGroup => slug == groupKey;
}
