import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/expense_filter_data.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/settings/category_viewmodel.dart';
import 'package:mybudget/ui/expenses/widgets/expense_card.dart';
import 'package:mybudget/ui/expenses/widgets/expense_bottom_sheet.dart';
import 'package:mybudget/ui/expenses/widgets/expense_filter_bottom_sheet.dart';
import 'package:mybudget/ui/expenses/widgets/financial_summary_card.dart';

class ExpensesList extends StatefulWidget {
  const ExpensesList({super.key});

  @override
  State<ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends State<ExpensesList> {
  ExpenseFilterData _filterData = ExpenseFilterData();

  @override
  Widget build(BuildContext context) {
    return Consumer3<ExpenseViewModel, AccountViewModel, CategoryViewModel>(
      builder: (context, expenseVM, accountVM, categoryVM, child) {
        List<ExpenseModel> displayedExpenses = expenseVM.expenses;

        if (!_filterData.isEmpty) {
          displayedExpenses =
              displayedExpenses.where((expense) {
                if (_filterData.startDate != null &&
                    expense.date.isBefore(_filterData.startDate!)) {
                  return false;
                }
                if (_filterData.endDate != null &&
                    expense.date.isAfter(_filterData.endDate!)) {
                  return false;
                }

                if (_filterData.minAmount != null &&
                    expense.amount < _filterData.minAmount!) {
                  return false;
                }
                if (_filterData.maxAmount != null &&
                    expense.amount > _filterData.maxAmount!) {
                  return false;
                }

                if (_filterData.categoryIds.isNotEmpty &&
                    !_filterData.categoryIds.contains(expense.categoryId)) {
                  return false;
                }

                if (_filterData.accountIds.isNotEmpty &&
                    !_filterData.accountIds.contains(expense.accountId)) {
                  return false;
                }

                return true;
              }).toList();
        }

        if (expenseVM.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final isEmpty = displayedExpenses.isEmpty && _filterData.isEmpty;

        return Column(
          children: [
            _buildHeaderContainer(
              context,
              displayedExpenses,
              expenseVM,
              isEmpty,
            ),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: 16,
                  bottom: 100,
                  left: 16,
                  right: 16,
                ),
                itemCount: displayedExpenses.length,
                itemBuilder: (context, index) {
                  final expense = displayedExpenses[index];
                  final account = accountVM.accounts.firstWhere(
                    (a) => a.id == expense.accountId,
                    orElse:
                        () => AccountModel.create(
                          name: 'Compte inconnu',
                          bank: '',
                        ),
                  );

                  return ExpenseCard(
                    expense: expense,
                    accountName: account.name,
                    onDelete: () {
                      expenseVM.deleteExpense(expense.id);
                    },
                    onEdit: () {
                      ExpenseBottomSheet.show(
                        context: context,
                        accounts: accountVM.accounts,
                        categories: categoryVM.categories,
                        expense: expense,
                        onSubmit: (updatedExpense) {
                          expenseVM.updateExpense(updatedExpense);
                        },
                        onCancel: () {},
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderContainer(
    BuildContext context,
    List<ExpenseModel> displayedExpenses,
    ExpenseViewModel expenseVM,
    bool isEmpty,
  ) {
    final errorColor = Theme.of(context).colorScheme.error;
    final totalExpenses = expenseVM.getTotalExpenses(displayedExpenses);
    final annualExpenses = expenseVM.getAnnualExpenses(displayedExpenses);

    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 15, bottom: 5),
            child: FinancialSummaryCard(
              title: 'Dépenses',
              titleIcon: Icons.money_off,
              primaryColor: errorColor,
              amount: totalExpenses,
              trendIcon: Icons.trending_down,
              itemCount: displayedExpenses.length,
              formatter: formatter,
              childContent: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        context: context,
                        title: 'Mensuel',
                        amount: totalExpenses,
                        icon: Icons.arrow_downward,
                        color: errorColor,
                        formatter: formatter,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatBox(
                        context: context,
                        title: 'Annuel',
                        amount: annualExpenses,
                        icon: Icons.date_range,
                        color: errorColor,
                        formatter: formatter,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildSectionHeader(context),
          if (isEmpty) _buildEmptyState(context),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required BuildContext context,
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required NumberFormat formatter,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mes transactions',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color:
                  _filterData.isEmpty
                      ? Theme.of(context).iconTheme.color
                      : Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune dépense enregistrée',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez vos dépenses pour commencer à gérer vos finances',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une dépense'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    ExpenseFilterBottomSheet.show(
      context: context,
      initialFilterData: _filterData,
      onApply: (updatedFilterData) {
        setState(() {
          _filterData = updatedFilterData;
        });
      },
      onClear: () {
        setState(() {
          _filterData = ExpenseFilterData();
        });
      },
      onCancel: () {},
    );
  }
}
