import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/core/controllers/category_controller.dart';
import 'package:mybudget/core/controllers/expense_controller.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/data/models/category_model.dart';
import 'package:mybudget/presentation/widgets/common/gradient_app_bar.dart';
import 'package:mybudget/presentation/widgets/common/section_header.dart';
import 'package:mybudget/presentation/widgets/expenses/expense_card.dart';
import 'package:mybudget/presentation/widgets/expenses/expense_bottom_sheet.dart';

class CategoryDetailScreen extends StatelessWidget {
  final int categoryId;

  const CategoryDetailScreen({required this.categoryId, super.key});

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.find<CategoryController>();
    final category = categoryController.getCategoryById(categoryId);

    if (category == null) {
      return const Scaffold(
        appBar: GradientAppBar(title: 'Catégorie introuvable'),
        body: Center(
          child: Text('Cette catégorie n\'existe pas ou a été supprimée.'),
        ),
      );
    }

    return Scaffold(
      appBar: GradientAppBar(title: category.name),
      body: Obx(() => _buildCategoryDetail(context, category)),
    );
  }

  Widget _buildCategoryDetail(BuildContext context, CategoryModel category) {
    final expenseController = Get.find<ExpenseController>();
    final accountController = Get.find<AccountController>();
    final accounts = accountController.accounts;

    final allExpenses = expenseController.expenses;
    final categoryExpenses =
        allExpenses.where((e) => e.categoryId == category.id).toList();

    final totalAmount = categoryExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalExpenseAmount = expenseController.getTotalExpenses();
    final percentageOfTotal =
        totalExpenseAmount > 0 ? (totalAmount / totalExpenseAmount) : 0.0;

    Map<int, double> accountUsage = {};
    for (var expense in categoryExpenses) {
      final accountId = expense.accountId;
      accountUsage[accountId] =
          (accountUsage[accountId] ?? 0.0) + expense.amount;
    }

    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Statistiques',
              actionIcon: null,
              onActionPressed: null,
            ),

            const SizedBox(height: 8),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                onTap: () {},
                splashColor: Theme.of(
                  context,
                ).colorScheme.primary.withAlpha(25),
                highlightColor: Theme.of(
                  context,
                ).colorScheme.primary.withAlpha(15),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.calculate_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Total des dépenses',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              formatter.format(totalAmount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.percent,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Pourcentage du total',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              '${(percentageOfTotal * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.receipt_long,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Nombre de transactions',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              categoryExpenses.length.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (accountUsage.isNotEmpty) ...[
              const SectionHeader(
                title: 'Utilisation par compte',
                actionIcon: null,
                onActionPressed: null,
              ),

              const SizedBox(height: 8),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                clipBehavior: Clip.hardEdge,
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: accountUsage.length,
                  itemBuilder: (context, index) {
                    final entry = accountUsage.entries.elementAt(index);
                    final account = accounts.firstWhere(
                      (a) => a.id == entry.key,
                      orElse: () => AccountModel()..name = 'Compte inconnu',
                    );

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (index > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(height: 1),
                          ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Get.toNamed('/accounts/${account.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.account_balance,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      account.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatter.format(entry.value),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
            ],

            const SectionHeader(
              title: 'Dépenses dans cette catégorie',
              actionIcon: null,
              onActionPressed: null,
            ),

            const SizedBox(height: 8),

            if (categoryExpenses.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Aucune dépense dans cette catégorie'),
                ),
              )
            else
              ...categoryExpenses.map((expense) {
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
                      expenseController.deleteExpense(expense.id);
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
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}
