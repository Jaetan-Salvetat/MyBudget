class ScannedItemModel {
  final String name;
  double amount;
  String? categoryName;
  int? categoryId;

  ScannedItemModel({
    required this.name,
    required this.amount,
    this.categoryName,
    this.categoryId,
  });
}
