import 'package:mybudget/core/enums/frequency.dart';

class ExpenseFilterData {
  int? startDay;
  int? endDay;
  double? minAmount;
  double? maxAmount;
  String? searchQuery;
  List<String> groupKeys;
  List<int> accountIds;
  List<Frequency> types;

  ExpenseFilterData({
    this.startDay,
    this.endDay,
    this.minAmount,
    this.maxAmount,
    this.searchQuery,
    this.groupKeys = const [],
    this.accountIds = const [],
    this.types = const [],
  });

  bool get isEmpty {
    return startDay == null &&
        endDay == null &&
        minAmount == null &&
        maxAmount == null &&
        (searchQuery == null || searchQuery!.isEmpty) &&
        groupKeys.isEmpty &&
        accountIds.isEmpty &&
        types.isEmpty;
  }

  int get activeCount {
    int count = 0;
    if (minAmount != null || maxAmount != null) count++;
    if (groupKeys.isNotEmpty) count++;
    if (accountIds.isNotEmpty) count++;
    if (types.isNotEmpty) count++;
    if (startDay != null || endDay != null) count++;
    return count;
  }

  ExpenseFilterData copyWith({
    int? startDay,
    int? endDay,
    double? minAmount,
    double? maxAmount,
    String? searchQuery,
    List<String>? groupKeys,
    List<int>? accountIds,
    List<Frequency>? types,
  }) {
    return ExpenseFilterData(
      startDay: startDay ?? this.startDay,
      endDay: endDay ?? this.endDay,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      searchQuery: searchQuery ?? this.searchQuery,
      groupKeys: groupKeys ?? this.groupKeys,
      accountIds: accountIds ?? this.accountIds,
      types: types ?? this.types,
    );
  }
}
