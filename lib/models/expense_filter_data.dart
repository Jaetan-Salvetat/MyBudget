class ExpenseFilterData {
  int? startDay;
  int? endDay;
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
