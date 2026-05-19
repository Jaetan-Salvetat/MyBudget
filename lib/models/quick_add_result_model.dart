class QuickAddResultModel {
  final String name;
  final double amount;
  final int? categoryId;
  final String? newCategory;
  final String? newCategoryIcon;
  final String? newCategoryColor;
  final String frequency;

  const QuickAddResultModel({
    required this.name,
    required this.amount,
    required this.frequency,
    this.categoryId,
    this.newCategory,
    this.newCategoryIcon,
    this.newCategoryColor,
  });

  factory QuickAddResultModel.fromJson(Map<String, dynamic> json) {
    return QuickAddResultModel(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'] as int?,
      newCategory: json['newCategory'] as String?,
      newCategoryIcon: json['newCategoryIcon'] as String?,
      newCategoryColor: json['newCategoryColor'] as String?,
      frequency: json['frequency'] as String,
    );
  }

  QuickAddResultModel copyWith({
    String? name,
    double? amount,
    int? categoryId,
    String? newCategory,
    String? newCategoryIcon,
    String? newCategoryColor,
    String? frequency,
  }) {
    return QuickAddResultModel(
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
