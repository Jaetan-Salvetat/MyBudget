import 'package:mybudget/core/enums/frequency.dart';

class TransactionFilterData {
  final double? minAmount;
  final double? maxAmount;
  final String? searchQuery;
  final List<String> groupKeys;
  final List<int> accountIds;
  final List<int> beneficiaryIds;
  final List<Frequency> types;

  const TransactionFilterData({
    this.minAmount,
    this.maxAmount,
    this.searchQuery,
    this.groupKeys = const [],
    this.accountIds = const [],
    this.beneficiaryIds = const [],
    this.types = const [],
  });

  bool get isEmpty {
    return minAmount == null &&
        maxAmount == null &&
        (searchQuery == null || searchQuery!.isEmpty) &&
        groupKeys.isEmpty &&
        accountIds.isEmpty &&
        beneficiaryIds.isEmpty &&
        types.isEmpty;
  }

  int get activeCount {
    int count = 0;
    if (minAmount != null || maxAmount != null) count++;
    if (groupKeys.isNotEmpty) count++;
    if (accountIds.isNotEmpty) count++;
    if (beneficiaryIds.isNotEmpty) count++;
    if (types.isNotEmpty) count++;
    return count;
  }

  TransactionFilterData copyWith({
    double? minAmount,
    double? maxAmount,
    String? searchQuery,
    List<String>? groupKeys,
    List<int>? accountIds,
    List<int>? beneficiaryIds,
    List<Frequency>? types,
  }) {
    return TransactionFilterData(
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      searchQuery: searchQuery ?? this.searchQuery,
      groupKeys: groupKeys ?? this.groupKeys,
      accountIds: accountIds ?? this.accountIds,
      beneficiaryIds: beneficiaryIds ?? this.beneficiaryIds,
      types: types ?? this.types,
    );
  }

  TransactionFilterData clearAmounts() {
    return TransactionFilterData(
      searchQuery: searchQuery,
      groupKeys: groupKeys,
      accountIds: accountIds,
      beneficiaryIds: beneficiaryIds,
      types: types,
    );
  }
}
