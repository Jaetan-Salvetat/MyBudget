class RevenueFilterData {
  double? minAmount;
  double? maxAmount;
  String? searchQuery;
  List<int> accountIds;
  List<int> beneficiaryIds;
  List<String> frequencies;

  RevenueFilterData({
    this.minAmount,
    this.maxAmount,
    this.searchQuery,
    this.accountIds = const [],
    this.beneficiaryIds = const [],
    this.frequencies = const [],
  });

  bool get isEmpty {
    return minAmount == null &&
        maxAmount == null &&
        (searchQuery == null || searchQuery!.isEmpty) &&
        accountIds.isEmpty &&
        beneficiaryIds.isEmpty &&
        frequencies.isEmpty;
  }

  int get activeCount {
    int count = 0;
    if (minAmount != null || maxAmount != null) count++;
    if (accountIds.isNotEmpty) count++;
    if (beneficiaryIds.isNotEmpty) count++;
    if (frequencies.isNotEmpty) count++;
    return count;
  }
}
