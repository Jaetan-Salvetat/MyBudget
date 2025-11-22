import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/expense_filter_data.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/settings/category_viewmodel.dart';
import 'package:mybudget/ui/expenses/widgets/expense_card.dart';
import 'package:mybudget/ui/expenses/widgets/expense_bottom_sheet.dart';
import 'package:mybudget/ui/expenses/widgets/expense_filter_bottom_sheet.dart';

class ExpensesList extends StatefulWidget {
  const ExpensesList({super.key});

  @override
  State<ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends State<ExpensesList> {
  ExpenseFilterData _filterData = ExpenseFilterData();
  bool _isSearchVisible = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ExpenseViewModel, AccountViewModel, CategoryViewModel>(
      builder: (context, expenseVM, accountVM, categoryVM, child) {
        List<ExpenseModel> displayedExpenses = expenseVM.expenses;

        if (!_filterData.isEmpty) {
          displayedExpenses =
              displayedExpenses.where((expense) {
                if (_filterData.searchQuery != null &&
                    _filterData.searchQuery!.isNotEmpty &&
                    !expense.name.toLowerCase().contains(
                      _filterData.searchQuery!.toLowerCase(),
                    )) {
                  return false;
                }

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

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            top: 120, // Added top padding for visual spacing
            bottom: 145,
            left: 16,
            right: 16,
          ),
          itemCount: displayedExpenses.length + 1, // +1 for header
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildHeaderContainer(
                context,
                displayedExpenses,
                expenseVM,
                isEmpty,
              );
            }

            final expense = displayedExpenses[index - 1];
            final account = accountVM.accounts.firstWhere(
              (a) => a.id == expense.accountId,
              orElse:
                  () => AccountModel.create(name: 'Compte inconnu', bank: ''),
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

    return Column(
      children: [
        FrostedCard(
          margin: const EdgeInsets.only(bottom: 24),
          borderRadius: 20,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Dépenses',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_down, color: errorColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${displayedExpenses.length} trans.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: errorColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  formatter.format(totalExpenses),
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: errorColor,
                    letterSpacing: -1.0,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatBox(
                      context: context,
                      title: 'Mensuel',
                      amount: totalExpenses,
                      icon: Icons.calendar_view_month,
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
                      icon: Icons.calendar_today,
                      color: errorColor,
                      formatter: formatter,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildSectionHeader(context),
        if (isEmpty) _buildEmptyState(context),
      ],
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
              fontSize: 16,
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
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Determine direction based on the child key
          // Title moves Left <-> Center
          // Search moves Right <-> Center
          final isSearch = child.key == const ValueKey('search');
          final beginOffset =
              isSearch ? const Offset(0.2, 0.0) : const Offset(-0.2, 0.0);

          final offsetAnimation = Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
        child:
            _isSearchVisible
                ? SizedBox(
                  key: const ValueKey('search'),
                  height: 60, // Fixed height to prevent jumping
                  child: Row(
                    children: [
                      Expanded(
                        child: FrostedTextField(
                          controller: _searchController,
                          hintText: 'Rechercher une dépense...',
                          prefixIcon: const Icon(Icons.search),
                          onChanged: (value) {
                            setState(() {
                              _filterData.searchQuery = value;
                            });
                          },
                          autofocus: true,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _isSearchVisible = false;
                            _searchController.clear();
                            _filterData.searchQuery = '';
                          });
                        },
                      ),
                    ],
                  ),
                )
                : SizedBox(
                  key: const ValueKey('title'),
                  height: 60, // Matching height
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mes transactions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.search,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () {
                              setState(() {
                                _isSearchVisible = true;
                              });
                            },
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
                    ],
                  ),
                ),
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
    final categoryVM = Provider.of<CategoryViewModel>(context, listen: false);
    final accountVM = Provider.of<AccountViewModel>(context, listen: false);

    ExpenseFilterBottomSheet.show(
      context: context,
      initialFilterData: _filterData,
      categories: categoryVM.categories,
      accounts: accountVM.accounts,
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
