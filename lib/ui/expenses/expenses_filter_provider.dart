import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/models/expense_filter_data.dart';

class ExpensesFilterNotifier extends Notifier<ExpenseFilterData> {
  @override
  ExpenseFilterData build() => ExpenseFilterData();

  void update(
    ExpenseFilterData Function(ExpenseFilterData filter) transform,
  ) {
    state = transform(state);
  }

  void showOnlyGroup(String groupKey) {
    state = ExpenseFilterData(groupKeys: [groupKey]);
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
    state = ExpenseFilterData(searchQuery: state.searchQuery);
  }
}

final expensesFilterProvider =
    NotifierProvider<ExpensesFilterNotifier, ExpenseFilterData>(
      ExpensesFilterNotifier.new,
    );
