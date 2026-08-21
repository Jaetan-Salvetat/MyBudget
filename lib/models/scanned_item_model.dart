class ScannedItemModel {
  final String name;
  final double amount;
  final double discount;
  final String? categoryName;
  final String? categorySlug;

  const ScannedItemModel({
    required this.name,
    required this.amount,
    this.discount = 0,
    this.categoryName,
    this.categorySlug,
  });

  double get effectiveAmount => amount - discount;

  bool get hasDiscount => discount > 0;

  ScannedItemModel copyWith({
    String? name,
    double? amount,
    double? discount,
    String? categoryName,
    String? categorySlug,
  }) {
    return ScannedItemModel(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      discount: discount ?? this.discount,
      categoryName: categoryName ?? this.categoryName,
      categorySlug: categorySlug ?? this.categorySlug,
    );
  }
}
