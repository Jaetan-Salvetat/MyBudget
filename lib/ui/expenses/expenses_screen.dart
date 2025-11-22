import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/settings/category_viewmodel.dart';
import 'package:mybudget/ui/expenses/widgets/expense_bottom_sheet.dart';
import 'package:mybudget/ui/expenses/widgets/expenses_list.dart';

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
    final content = Column(
      children: [
        const SizedBox(height: 100),
        Expanded(child: const ExpensesList()),
      ],
    );

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

    return Scaffold(
      appBar: AppBar(title: const Text('Dépenses'), elevation: 0),
      floatingActionButton: FloatingActionButton(
        heroTag: fabTag,
        onPressed: () => _showAddExpenseBottomSheet(context),
        tooltip: 'Ajouter une dépense',
        child: const Icon(Icons.add),
      ),
      body: content,
    );
  }

  void _showAddExpenseBottomSheet(BuildContext context) {
    final accountViewModel = Provider.of<AccountViewModel>(
      context,
      listen: false,
    );
    final expenseViewModel = Provider.of<ExpenseViewModel>(
      context,
      listen: false,
    );
    final categoryViewModel = Provider.of<CategoryViewModel>(
      context,
      listen: false,
    );

    if (accountViewModel.accounts.isEmpty) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Aucun compte disponible'),
              content: const Text(
                'Vous devez d\'abord créer un compte avant d\'ajouter une dépense.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

     
    if (categoryViewModel.categories.isEmpty) {
       
    }

    ExpenseBottomSheet.show(
      context: context,
      accounts: accountViewModel.accounts,
      categories: categoryViewModel.categories,
      onSubmit: (expense) async {
        try {
          await expenseViewModel.addExpense(expense);
           
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur lors de l\'ajout: $e')),
            );
          }
        }
      },
      onCancel: () {},
    );
  }
}
