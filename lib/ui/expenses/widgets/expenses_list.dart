import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_filter_data.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/settings/beneficiary_viewmodel.dart';
import 'package:mybudget/ui/settings/category_viewmodel.dart';
import 'package:mybudget/ui/expenses/widgets/expense_card.dart';
import 'package:mybudget/ui/expenses/widgets/expense_bottom_sheet.dart';
import 'package:mybudget/ui/expenses/widgets/expense_filter_bottom_sheet.dart';

import 'package:mybudget/ui/expenses/widgets/expenses_summary_card.dart';
import 'package:mybudget/ui/common/empty_state.dart';

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
    return Consumer4<ExpenseViewModel, AccountViewModel, CategoryViewModel,
        BeneficiaryViewModel>(
      builder: (context, expenseVM, accountVM, categoryVM, beneficiaryVM, child) {
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
            top: 120,
            bottom: 145,
            left: 16,
            right: 16,
          ),
          itemCount: displayedExpenses.length + 1,
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

            final beneficiary =
                expense.beneficiaryId != null
                    ? beneficiaryVM.getBeneficiaryById(expense.beneficiaryId!)
                    : null;

            final category = categoryVM.categories.firstWhere(
              (c) => c.id == expense.categoryId,
              orElse: () => CategoryModel.create(name: 'Autre', icon: 'category'),
            );

            return ExpenseCard(
              expense: expense,
              accountName: account.name,
              beneficiaryName: beneficiary?.name,
              category: category,
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
    final totalExpenses = expenseVM.getTotalExpenses(displayedExpenses);
    final annualExpenses = expenseVM.getAnnualExpenses(displayedExpenses);

    return Column(
      children: [
        ExpensesSummaryCard(
          totalExpenses: totalExpenses,
          transactionCount: displayedExpenses.length,
          monthlyExpenses: totalExpenses,
          annualExpenses: annualExpenses,
        ),
        _buildSectionHeader(context),
        if (isEmpty) _buildEmptyState(context),
      ],
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
                  height: 60,
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
                  height: 60,
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
    return EmptyState(
      message: 'Aucune dépense enregistrée',
      subMessage: 'Ajoutez vos dépenses pour commencer à gérer vos finances',
      icon: Icons.receipt_long_outlined,
      buttonText: 'Ajouter une dépense',
      onPressed: () {
        final categoryVM = Provider.of<CategoryViewModel>(
          context,
          listen: false,
        );
        final accountVM = Provider.of<AccountViewModel>(context, listen: false);
        final expenseVM = Provider.of<ExpenseViewModel>(context, listen: false);
        ExpenseBottomSheet.show(
          context: context,
          accounts: accountVM.accounts,
          categories: categoryVM.categories,
          onSubmit: (newExpense) {
            expenseVM.addExpense(newExpense);
          },
          onCancel: () {},
        );
      },
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
