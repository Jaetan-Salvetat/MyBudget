import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/models/expense_model.dart';

class AccountExpenseList extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final NumberFormat formatter;

  const AccountExpenseList({
    required this.expenses,
    required this.formatter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text("Aucune dépense")),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      separatorBuilder:
          (context, index) => FrostedDivider(
            height: 1,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.error.withValues(alpha: 0.1),
            child: Icon(
              Icons.arrow_downward,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
          ),
          title: Text(
            expense.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(DateFormat('dd/MM/yyyy').format(expense.date)),
          trailing: Text(
            formatter.format(expense.amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        );
      },
    );
  }
}
