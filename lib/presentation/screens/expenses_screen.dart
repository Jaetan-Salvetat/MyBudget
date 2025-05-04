import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/common/app_scaffold.dart';
import '../../core/controllers/expense_controller.dart';
import '../../core/controllers/account_controller.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/account_model.dart';
import '../widgets/expenses/expense_bottom_sheet.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dépenses',
      useNestedAppBar: false,
      child: const ExpensesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseBottomSheet(context),
        tooltip: 'Ajouter une dépense',
        child: const Icon(Icons.add),
      ),
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

class ExpensesList extends StatelessWidget {
  const ExpensesList({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseController = Get.find<ExpenseController>();
    final accountController = Get.find<AccountController>();
    
    return Obx(() {
      final expenses = expenseController.expenses;
      final accounts = accountController.accounts;

      if (expenses.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.money_off,
                size: 72,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Aucune dépense enregistrée',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ExpenseBottomSheet.show(
                    context: context,
                    accounts: accountController.accounts,
                    onSubmit: (expense) {
                      Get.find<ExpenseController>().addExpense(expense);
                      Get.back();
                    },
                    onCancel: () => Get.back(),
                  );
                },
                child: const Text('Ajouter une dépense'),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.only(top: 130, bottom: 16, left: 16, right: 16),
        itemCount: expenses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final expense = expenses[index];
          // Récupérer le compte associé à la dépense
          AccountModel? account;
          if (accounts.isNotEmpty) {
            try {
              account = accounts.firstWhere((a) => a.id == expense.accountId);
            } catch (_) {
              // Si aucun compte correspondant n'est trouvé, on utilise le premier
              account = accounts.first;
            }
          }

          return ExpenseCard(
            expense: expense,
            accountName: account?.name ?? 'Compte inconnu',
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
          );
        },
      );
    });
  }
}

class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final String accountName;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ExpenseCard({
    required this.expense,
    required this.accountName,
    required this.onDelete,
    required this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(expense.category),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.name,
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        accountName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${expense.amount.toStringAsFixed(2)} €',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Chip(
                  label: Text(expense.category),
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    _formatDate(expense.date, expense.frequency),
                  ),
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmer la suppression'),
                        content: Text(
                          'Voulez-vous vraiment supprimer ${expense.name} ?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () {
                              onDelete();
                              Get.back();
                            },
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Alimentation':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Logement':
        return Icons.home;
      case 'Loisirs':
        return Icons.sports_esports;
      case 'Santé':
        return Icons.medical_services;
      case 'Vêtements':
        return Icons.shopping_bag;
      default:
        return Icons.category;
    }
  }

  String _formatDate(DateTime date, String frequency) {
    switch (frequency) {
      case 'Unique':
        return '${date.day}/${date.month}/${date.year}';
      case 'Mensuel':
        return 'Jour ${date.day}';
      case 'Hebdomadaire':
        final days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
        return days[date.weekday % 7];
      case 'Annuel':
        final months = [
          'Jan',
          'Fév',
          'Mar',
          'Avr',
          'Mai',
          'Juin',
          'Juil',
          'Août',
          'Sep',
          'Oct',
          'Nov',
          'Déc',
        ];
        return '${date.day} ${months[date.month - 1]}';
      default:
        return '${date.day}/${date.month}/${date.year}';
    }
  }
}
