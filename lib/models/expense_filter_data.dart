class ExpenseFilterData {
  DateTime? startDate;
  DateTime? endDate;
  double? minAmount;
  double? maxAmount;
  String? searchQuery;
  List<int> categoryIds;
  List<int> accountIds;

  ExpenseFilterData({
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.searchQuery,
    this.categoryIds = const [],
    this.accountIds = const [],
  });

  bool get isEmpty {
    return startDate == null &&
        endDate == null &&
        minAmount == null &&
        maxAmount == null &&
        (searchQuery == null || searchQuery!.isEmpty) &&
        categoryIds.isEmpty &&
        accountIds.isEmpty;
  }
}
