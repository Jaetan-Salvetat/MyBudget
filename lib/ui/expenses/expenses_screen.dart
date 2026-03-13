import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/expense_filter_data.dart';
import 'package:mybudget/ui/expenses/widgets/expenses_list.dart';

class ExpensesScreen extends StatelessWidget {
  final ExpenseFilterData? initialFilter;
  final bool standalone;

  const ExpensesScreen({
    super.key,
    this.initialFilter,
    this.standalone = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [Expanded(child: ExpensesList(initialFilter: initialFilter))],
    );

    if (standalone) {
      return FrostedScaffold(
        appBar: const FrostedAppBar(title: 'Dépenses'),
        child: content,
      );
    }

    return content;
  }
}
