import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/core/controllers/expense_controller.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/data/models/expense_model.dart';
import 'package:mybudget/presentation/widgets/expenses/expense_card.dart';
import 'package:mybudget/presentation/widgets/expenses/expense_bottom_sheet.dart';

class CategoryExpensesList extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final List<AccountModel> accounts;

  const CategoryExpensesList({
    required this.expenses,
    required this.accounts,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('Aucune dépense dans cette catégorie'),
        ),
      );
    }

    return Column(
      children: expenses.map((expense) {
        final account = accounts.firstWhere(
          (a) => a.id == expense.accountId,
          orElse: () => AccountModel()..name = 'Compte inconnu',
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ExpenseCard(
            expense: expense,
            accountName: account.name,
            onDelete: () {
              Get.find<ExpenseController>().deleteExpense(expense.id);
            },
            onEdit: () {
              ExpenseBottomSheet.show(
                context: context,
                accounts: accounts,
                expense: expense,
                onSubmit: (updatedExpense) {
                  Get.find<ExpenseController>().updateExpense(updatedExpense);
                  Get.back();
                },
                onCancel: () => Get.back(),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
