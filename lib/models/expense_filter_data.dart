class ExpenseFilterData {
  DateTime? startDate;
  DateTime? endDate;
  double? minAmount;
  double? maxAmount;
  List<int> categoryIds;
  List<int> accountIds;

  ExpenseFilterData({
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.categoryIds = const [],
    this.accountIds = const [],
  });

  bool get isEmpty {
    return startDate == null &&
        endDate == null &&
        minAmount == null &&
        maxAmount == null &&
        categoryIds.isEmpty &&
        accountIds.isEmpty;
  }
}
