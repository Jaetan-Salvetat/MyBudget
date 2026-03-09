class RevenueFilterData {
  double? minAmount;
  double? maxAmount;
  String? searchQuery;
  List<int> accountIds;
  List<int> beneficiaryIds;

  RevenueFilterData({
    this.minAmount,
    this.maxAmount,
    this.searchQuery,
    this.accountIds = const [],
    this.beneficiaryIds = const [],
  });

  bool get isEmpty {
    return minAmount == null &&
        maxAmount == null &&
        (searchQuery == null || searchQuery!.isEmpty) &&
        accountIds.isEmpty &&
        beneficiaryIds.isEmpty;
  }
}
