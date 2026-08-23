import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/models/transaction_filter_data.dart';

class TransactionFilterNotifier extends Notifier<TransactionFilterData> {
  @override
  TransactionFilterData build() => const TransactionFilterData();

  void update(
    TransactionFilterData Function(TransactionFilterData filter) transform,
  ) {
    state = transform(state);
  }

  void showOnlyGroup(String groupKey) {
    state = TransactionFilterData(groupKeys: [groupKey]);
  }

  void toggleGroup(String groupKey) {
    final groupKeys = List<String>.from(state.groupKeys);
    if (!groupKeys.remove(groupKey)) groupKeys.add(groupKey);
    state = state.copyWith(groupKeys: groupKeys);
  }

  void clearGroups() {
    state = state.copyWith(groupKeys: const []);
  }

  void reset() {
    state = TransactionFilterData(searchQuery: state.searchQuery);
  }

  void clearAll() {
    state = const TransactionFilterData();
  }
}

final expensesFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilterData>(
      TransactionFilterNotifier.new,
    );

final revenuesFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilterData>(
      TransactionFilterNotifier.new,
    );
