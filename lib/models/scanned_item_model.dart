class ScannedItemModel {
  final String name;
  final double amount;
  final String? categoryName;
  final int? categoryId;

  const ScannedItemModel({
    required this.name,
    required this.amount,
    this.categoryName,
    this.categoryId,
  });

  ScannedItemModel copyWith({
    String? name,
    double? amount,
    String? categoryName,
    int? categoryId,
  }) {
    return ScannedItemModel(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryName: categoryName ?? this.categoryName,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}
