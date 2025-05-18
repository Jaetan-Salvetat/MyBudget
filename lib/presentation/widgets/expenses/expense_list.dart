import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/core/controllers/expense_controller.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/data/models/expense_model.dart';
import 'package:mybudget/presentation/widgets/common/empty_state_view.dart';
import 'package:mybudget/presentation/widgets/common/financial_summary_card.dart';
import 'package:mybudget/presentation/widgets/common/section_header.dart';
import 'package:mybudget/presentation/widgets/expenses/expense_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/expenses/expense_card.dart';
import 'package:mybudget/presentation/widgets/expenses/expense_filter_bottom_sheet.dart';

class ExpensesList extends StatefulWidget {
  final bool isNested;

  const ExpensesList({this.isNested = false, super.key});

  @override
  State<ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends State<ExpensesList> {
  final RxList<ExpenseModel> filteredExpenses = <ExpenseModel>[].obs;
  final Rx<ExpenseFilterData> filterData = ExpenseFilterData().obs;
  
  @override
  void initState() {
    super.initState();
    _updateFilteredExpenses();
  }
  
  void _updateFilteredExpenses() {
    final expenseController = Get.find<ExpenseController>();
    filteredExpenses.value = expenseController.expenses.applyFilter(filterData.value);
  }

  @override
  Widget build(BuildContext context) {
    final expenseController = Get.find<ExpenseController>();
    final accountController = Get.find<AccountController>();

    return Obx(() {
      final expenses = expenseController.expenses;
      final accounts = accountController.accounts;
      final displayedExpenses = filteredExpenses.isEmpty && filterData.value.isEmpty 
          ? expenses 
          : filteredExpenses;

      return Expanded(
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: displayedExpenses.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildHeaderContainer(context, displayedExpenses.isEmpty);
            }

            final expense = displayedExpenses[index - 1];
            final account = accounts.firstWhere(
              (a) => a.id == expense.accountId,
              orElse: () => AccountModel()..name = 'Compte inconnu',
            );

            return ExpenseCard(
              expense: expense,
              accountName: account.name,
              onDelete: () {
                Get.find<ExpenseController>().deleteExpense(expense.id);
                _updateFilteredExpenses();
              },
              onEdit: () {
                ExpenseBottomSheet.show(
                  context: context,
                  accounts: accounts,
                  expense: expense,
                  onSubmit: (updatedExpense) {
                    Get.find<ExpenseController>().updateExpense(updatedExpense);
                    _updateFilteredExpenses();
                    Get.back();
                  },
                  onCancel: () => Get.back(),
                );
              },
            );
          },
        ),
      );
    });
  }
  
  void _showFilterBottomSheet(BuildContext context) {
    ExpenseFilterBottomSheet.show(
      context: context,
      initialFilterData: filterData.value,
      onApply: (updatedFilterData) {
        filterData.value = updatedFilterData;
        _updateFilteredExpenses();
        Get.back();
      },
      onCancel: () => Get.back(),
      onClear: () {
        filterData.value = ExpenseFilterData();
        _updateFilteredExpenses();
        Get.back();
      },
    );
  }

  Widget _buildHeaderContainer(BuildContext context, bool isEmpty) {
    final expenseController = Get.find<ExpenseController>();

    final expenses = expenseController.expenses;
    final totalExpenses = expenseController.getTotalExpenses();
    final errorColor = Theme.of(context).colorScheme.error;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 15, bottom: 5),
          child: Obx(() {
            final formatter = NumberFormat.currency(
              locale: 'fr_FR',
              symbol: '€',
            );

            return FinancialSummaryCard(
              title: 'Dépenses',
              titleIcon: Icons.money_off,
              primaryColor: errorColor,
              amount: totalExpenses,
              trendIcon: Icons.trending_down,
              itemCount: expenses.length,
              formatter: formatter,
              childContent: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: errorColor.withOpacity(0.08),
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
                                  color: errorColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Mensuel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: errorColor.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formatter.format(totalExpenses),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: errorColor.withOpacity(0.08),
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
                                  color: errorColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Annuel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: errorColor.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formatter.format(totalExpenses * 12),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        SectionHeader(
          title: 'Mes transactions',
          actionIcon: Icons.filter_list,
          onActionPressed: () => _showFilterBottomSheet(context),
        ),
        if (isEmpty)
          EmptyStateView(
            title: 'Aucune dépense enregistrée',
            message: 'Ajoutez vos dépenses pour commencer à gérer vos finances',
            icon: Icons.add,
            buttonText: 'Ajouter une dépense',
            onButtonPressed: () => _showAddExpenseBottomSheet(context),
          ),
      ],
    );
  }

  void _showAddExpenseBottomSheet(BuildContext context) {
    final expenseController = Get.find<ExpenseController>();
    final accountController = Get.find<AccountController>();

    ExpenseBottomSheet.show(
      context: context,
      accounts: accountController.accounts,
      onSubmit: (expense) {
        expenseController.addExpense(expense);
        _updateFilteredExpenses();
        Get.back();
      },
      onCancel: () => Get.back(),
    );
  }
}
