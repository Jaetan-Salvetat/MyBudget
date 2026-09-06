import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/enums/expense_group_by.dart';
import 'package:mybudget/data/service/preferences_service.dart';

class ExpensesGroupByNotifier extends Notifier<ExpenseGroupBy> {
  @override
  ExpenseGroupBy build() {
    return ExpenseGroupBy.fromName(PreferencesService.getExpensesGroupBy());
  }

  Future<void> set(ExpenseGroupBy value) async {
    state = value;
    await PreferencesService.setExpensesGroupBy(value.name);
  }
}

final expensesGroupByProvider =
    NotifierProvider<ExpensesGroupByNotifier, ExpenseGroupBy>(
      ExpensesGroupByNotifier.new,
    );
