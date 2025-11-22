import 'package:flutter/material.dart';
import 'package:mybudget/ui/expenses/widgets/expenses_list.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(children: [Expanded(child: ExpensesList())]);
  }
}
