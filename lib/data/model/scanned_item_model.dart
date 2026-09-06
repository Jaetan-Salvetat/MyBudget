import 'package:mybudget/core/constants/category_confidence.dart';

class ScannedItemModel {
  const ScannedItemModel({
    required this.name,
    required this.amount,
    this.discount = 0,
    this.categoryName,
    this.categorySlug,
    this.categoryConfidence = 0,
    this.confirmedByUser = false,
  });
  final String name;
  final double amount;
  final double discount;
  final String? categoryName;
  final String? categorySlug;

  final double categoryConfidence;

  final bool confirmedByUser;

  double get effectiveAmount => amount - discount;

  bool get hasDiscount => discount > 0;

  bool get isRanked => categorySlug != null;

  bool get isCategoryUncertain =>
      isRanked &&
      !confirmedByUser &&
      categoryConfidence < kCategoryConfidenceThreshold;

  bool get needsAttention => !isRanked || isCategoryUncertain;

  ScannedItemModel copyWith({
    String? name,
    double? amount,
    double? discount,
    String? categoryName,
    String? categorySlug,
    double? categoryConfidence,
    bool? confirmedByUser,
  }) {
    return ScannedItemModel(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      discount: discount ?? this.discount,
      categoryName: categoryName ?? this.categoryName,
      categorySlug: categorySlug ?? this.categorySlug,
      categoryConfidence: categoryConfidence ?? this.categoryConfidence,
      confirmedByUser: confirmedByUser ?? this.confirmedByUser,
    );
  }
}
