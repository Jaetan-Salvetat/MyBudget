import 'package:mybudget/core/enums/transaction_type.dart';

class QuickAddResultModel {
  final TransactionType type;
  final String name;
  final double amount;
  final int? categoryId;
  final String? newCategory;
  final String? newCategoryIcon;
  final int? newCategoryColor;
  final String frequency;

  const QuickAddResultModel({
    required this.type,
    required this.name,
    required this.amount,
    required this.frequency,
    this.categoryId,
    this.newCategory,
    this.newCategoryIcon,
    this.newCategoryColor,
  });

  QuickAddResultModel copyWith({
    TransactionType? type,
    String? name,
    double? amount,
    int? categoryId,
    String? newCategory,
    String? newCategoryIcon,
    int? newCategoryColor,
    String? frequency,
  }) {
    return QuickAddResultModel(
      type: type ?? this.type,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      newCategory: newCategory ?? this.newCategory,
      newCategoryIcon: newCategoryIcon ?? this.newCategoryIcon,
      newCategoryColor: newCategoryColor ?? this.newCategoryColor,
      frequency: frequency ?? this.frequency,
    );
  }
}
