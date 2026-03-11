import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_filter_data.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/settings/beneficiary_provider.dart';
import 'package:mybudget/ui/settings/category_provider.dart';
import 'package:mybudget/ui/expenses/widgets/expense_card.dart';
import 'package:mybudget/ui/expenses/widgets/expense_bottom_sheet.dart';
import 'package:mybudget/ui/expenses/widgets/expense_filter_bottom_sheet.dart';

import 'package:mybudget/ui/expenses/widgets/expenses_summary_card.dart';
import 'package:mybudget/ui/common/empty_state.dart';

class ExpensesList extends ConsumerStatefulWidget {
  const ExpensesList({super.key});

  @override
  ConsumerState<ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends ConsumerState<ExpensesList> {
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
    return ref
        .watch(expenseProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erreur: $error')),
          data: (expensesRaw) {
            final accounts = ref.watch(accountProvider).value ?? [];
            final categories = ref.watch(categoryProvider).value ?? [];
            final beneficiaries = ref.watch(beneficiaryProvider).value ?? [];

            List<ExpenseModel> displayedExpenses = expensesRaw;

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

                    if (_filterData.startDay != null &&
                        expense.date.day < _filterData.startDay!) {
                      return false;
                    }
                    if (_filterData.endDay != null &&
                        expense.date.day > _filterData.endDay!) {
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

                    if (_filterData.frequencies.isNotEmpty &&
                        !_filterData.frequencies.contains(expense.frequency)) {
                      return false;
                    }

                    return true;
                  }).toList();
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
                    isEmpty,
                  );
                }

                final expense = displayedExpenses[index - 1];
                final account = accounts.firstWhere(
                  (a) => a.id == expense.accountId,
                  orElse:
                      () =>
                          AccountModel.create(name: 'Compte inconnu', bank: ''),
                );

                final beneficiary =
                    expense.beneficiaryId != null
                        ? beneficiaries
                            .where((b) => b.id == expense.beneficiaryId)
                            .firstOrNull
                        : null;

                final category = categories.firstWhere(
                  (c) => c.id == expense.categoryId,
                  orElse:
                      () =>
                          CategoryModel.create(name: 'Autre', icon: 'category'),
                );

                return ExpenseCard(
                  expense: expense,
                  accountName: account.name,
                  beneficiary: beneficiary,
                  category: category,
                  onDelete: () async {
                    try {
                      await ref
                          .read(expenseProvider.notifier)
                          .deleteExpense(expense.id);
                    } catch (e) {
                      if (context.mounted) {
                        FrostedSnackbar.show(
                          context,
                          message: 'Erreur lors de la suppression: \$e',
                        );
                      }
                    }
                  },
                  onEdit: () {
                    ExpenseBottomSheet.show(
                      context: context,
                      accounts: accounts,
                      categories: categories,
                      expense: expense,
                      onSubmit: (updatedExpense) async {
                        try {
                          await ref
                              .read(expenseProvider.notifier)
                              .updateExpense(updatedExpense);
                        } catch (e) {
                          if (context.mounted) {
                            FrostedSnackbar.show(
                              context,
                              message: 'Erreur lors de la modification: \$e',
                            );
                          }
                        }
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
    bool isEmpty,
  ) {
    final totalExpenses = ref
        .read(expenseProvider.notifier)
        .getTotalExpenses(displayedExpenses);
    final annualExpenses = ref
        .read(expenseProvider.notifier)
        .getAnnualExpenses(displayedExpenses);

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
        final accounts = ref.read(accountProvider).value ?? [];
        final categories = ref.read(categoryProvider).value ?? [];
        ExpenseBottomSheet.show(
          context: context,
          accounts: accounts,
          categories: categories,
          onSubmit: (newExpense) async {
            try {
              await ref.read(expenseProvider.notifier).addExpense(newExpense);
            } catch (e) {
              if (context.mounted) {
                FrostedSnackbar.show(
                  context,
                  message: 'Erreur lors de l\'ajout: \$e',
                );
              }
            }
          },
          onCancel: () {},
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final categories = ref.read(categoryProvider).value ?? [];
    final accounts = ref.read(accountProvider).value ?? [];

    ExpenseFilterBottomSheet.show(
      context: context,
      initialFilterData: _filterData,
      categories: categories,
      accounts: accounts,
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
