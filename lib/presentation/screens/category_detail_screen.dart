import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/core/controllers/category_controller.dart';
import 'package:mybudget/core/controllers/expense_controller.dart';
import 'package:mybudget/data/models/category_model.dart';
import 'package:mybudget/presentation/widgets/category_details/account_usage_section.dart';
import 'package:mybudget/presentation/widgets/category_details/category_expenses_list.dart';
import 'package:mybudget/presentation/widgets/category_details/category_statistics_section.dart';
import 'package:mybudget/presentation/widgets/common/gradient_app_bar.dart';
import 'package:mybudget/presentation/widgets/settings/category_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/settings/dialog_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/common/section_header.dart';

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
      appBar: GradientAppBar(
        title: category.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditCategoryDialog(context, category),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context, category),
          ),
        ],
      ),
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

            CategoryStatisticsSection(
              totalAmount: totalAmount,
              percentageOfTotal: percentageOfTotal,
              transactionCount: categoryExpenses.length,
            ),

            const SizedBox(height: 24),

            if (accountUsage.isNotEmpty) ...[
              const SectionHeader(
                title: 'Utilisation par compte',
                actionIcon: null,
                onActionPressed: null,
              ),

              const SizedBox(height: 8),

              AccountUsageSection(
                accountUsage: accountUsage,
                accounts: accounts,
              ),

              const SizedBox(height: 24),
            ],

            const SectionHeader(
              title: 'Dépenses dans cette catégorie',
              actionIcon: null,
              onActionPressed: null,
            ),

            const SizedBox(height: 8),

            CategoryExpensesList(
              expenses: categoryExpenses,
              accounts: accounts,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEditCategoryDialog(BuildContext context, CategoryModel category) {
    CategoryBottomSheet.show(
      context: context,
      initialName: category.name,
      initialIcon: category.icon,
      onSubmit: (name, icon) {
        final updatedCategory = CategoryModel()
          ..id = category.id
          ..name = name
          ..icon = icon;
        Get.find<CategoryController>().updateCategory(updatedCategory);
      },
    );
  }
  
  void _showDeleteConfirmation(BuildContext context, CategoryModel category) {
    final expenseController = Get.find<ExpenseController>();
    final categoryExpenses = expenseController.expenses.where((e) => e.categoryId == category.id).toList();
    
    if (categoryExpenses.isNotEmpty) {
      // La catégorie a des dépenses, empêcher la suppression
      DialogBottomSheet.showConfirmation(
        context: context,
        title: 'Suppression impossible',
        message: 'La catégorie ${category.name} ne peut pas être supprimée car elle est utilisée par ${categoryExpenses.length} dépense(s).\n\nVeuillez d\'abord supprimer ou réaffecter ces dépenses avant de supprimer la catégorie.',
        cancelLabel: 'Compris',
        showConfirmButton: false,
      );
    } else {
      // La catégorie n'a pas de dépenses, autoriser la suppression
      DialogBottomSheet.showConfirmation(
        context: context,
        title: 'Supprimer la catégorie',
        message: 'Êtes-vous sûr de vouloir supprimer la catégorie ${category.name} ?',
        cancelLabel: 'Annuler',
        confirmLabel: 'Supprimer',
        isDestructive: true,
        onConfirm: () {
          Get.find<CategoryController>().deleteCategory(category.id);
          Get.back();
        },
      );
    }
  }
}
