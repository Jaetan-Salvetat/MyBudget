import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../widgets/common/app_scaffold.dart';
import '../../core/controllers/expense_controller.dart';
import '../../core/controllers/account_controller.dart';
import '../../core/controllers/category_controller.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';
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
    if (isNested) {
      return Stack(
        children: [
          const ExpensesList(isNested: true),
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
      child: const ExpensesList(),
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
  final bool isNested;

  const ExpensesList({this.isNested = false, super.key});

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

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 130, 16, 5),
            child: Card(
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.05),
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.error.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.money_off,
                                color: Theme.of(context).colorScheme.error,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Dépenses',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.trending_down,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${expenses.length}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Obx(() {
                          final totalExpenses =
                              expenseController.getTotalExpenses();
                          final formatter = NumberFormat.currency(
                            locale: 'fr_FR',
                            symbol: '€',
                          );

                          return Text(
                            formatter.format(totalExpenses),
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.error,
                              letterSpacing: -0.5,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_downward,
                                      size: 16,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Mensuel',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Obx(() {
                                  final monthlyExpenses =
                                      expenseController.getTotalExpenses();
                                  final formatter = NumberFormat.currency(
                                    locale: 'fr_FR',
                                    symbol: '€',
                                  );

                                  return Text(
                                    formatter.format(monthlyExpenses),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.date_range,
                                      size: 16,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Annuel',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Obx(() {
                                  final totalExpenses =
                                      expenseController.getTotalExpenses() * 12;
                                  final formatter = NumberFormat.currency(
                                    locale: 'fr_FR',
                                    symbol: '€',
                                  );

                                  return Text(
                                    formatter.format(totalExpenses),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: expenses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final expense = expenses[index];
                AccountModel? account;
                if (accounts.isNotEmpty) {
                  try {
                    account = accounts.firstWhere(
                      (a) => a.id == expense.accountId,
                    );
                  } catch (_) {
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
                        Get.find<ExpenseController>().updateExpense(
                          updatedExpense,
                        );
                        Get.back();
                      },
                      onCancel: () => Get.back(),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(expense.categoryId),
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        accountName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${expense.amount.toStringAsFixed(2)} €',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (expense.frequency != 'Unique')
                  Chip(
                    label: Text(expense.frequency),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(_formatDate(expense.date, expense.frequency)),
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
                      builder:
                          (context) => AlertDialog(
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

  IconData _getCategoryIcon(int categoryId) {
    final categoryController = Get.find<CategoryController>();
    final category = categoryController.categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => CategoryModel()..icon = 'category', // Default icon
    );

    switch (category.icon) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'medical_services':
        return Icons.medical_services;
      case 'shopping_bag':
        return Icons.shopping_bag;
      default:
        return Icons.category;
    }
  }

  String _getCategoryName(int categoryId) {
    final categoryController = Get.find<CategoryController>();
    final category = categoryController.categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => CategoryModel()..name = 'Autre',
    );
    return category.name;
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
