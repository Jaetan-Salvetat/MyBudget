import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/presentation/widgets/expenses/expense_list.dart';
import '../widgets/common/app_scaffold.dart';
import '../../core/controllers/expense_controller.dart';
import '../../core/controllers/account_controller.dart';
import '../widgets/expenses/expense_bottom_sheet.dart';

class ExpensesScreen extends StatelessWidget {
  final bool isNested;
  final String fabTag;

  const ExpensesScreen({
    this.isNested = false,
    this.fabTag = 'expenses_fab',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const content = Column(children: [SizedBox(height: 100), ExpensesList()]);

    if (isNested) {
      return Stack(
        children: [
          content,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: fabTag,
              onPressed: () => _showAddExpenseBottomSheet(context),
              tooltip: 'Ajouter une dépense',
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }

    return AppScaffold(
      title: 'Dépenses',
      useNestedAppBar: false,
      floatingActionButton: FloatingActionButton(
        heroTag: fabTag,
        onPressed: () => _showAddExpenseBottomSheet(context),
        tooltip: 'Ajouter une dépense',
        child: const Icon(Icons.add),
      ),
      child: content,
    );
  }

  void _showAddExpenseBottomSheet(BuildContext context) {
    final accountController = Get.find<AccountController>();
    final expenseController = Get.find<ExpenseController>();

    ExpenseBottomSheet.show(
      context: context,
      accounts: accountController.accounts,
      onSubmit: (expense) {
        expenseController.addExpense(expense);
        Get.back();
      },
      onCancel: () => Get.back(),
    );
  }
}
