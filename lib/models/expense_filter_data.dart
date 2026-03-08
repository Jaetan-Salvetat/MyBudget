class ExpenseFilterData {
  int? startDay; // jour du mois, 1-31
  int? endDay; // jour du mois, 1-31
  double? minAmount;
  double? maxAmount;
  String? searchQuery;
  List<int> categoryIds;
  List<int> accountIds;

  ExpenseFilterData({
    this.startDay,
    this.endDay,
    this.minAmount,
    this.maxAmount,
    this.searchQuery,
    this.categoryIds = const [],
    this.accountIds = const [],
  });

  bool get isEmpty {
    return startDay == null &&
        endDay == null &&
        minAmount == null &&
        maxAmount == null &&
        (searchQuery == null || searchQuery!.isEmpty) &&
        categoryIds.isEmpty &&
        accountIds.isEmpty;
  }
}
