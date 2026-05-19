import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
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
import 'package:mybudget/ui/common/widgets/month_selector.dart';

class ExpensesList extends ConsumerStatefulWidget {
  final ExpenseFilterData? initialFilter;

  const ExpensesList({super.key, this.initialFilter});

  @override
  ConsumerState<ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends ConsumerState<ExpensesList> {
  late ExpenseFilterData _filterData;
  bool _isSearchVisible = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _filterData = widget.initialFilter ?? ExpenseFilterData();
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
          loading: () => const Center(child: FrostedCircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erreur: $error')),
          data: (expensesRaw) {
            final selectedMonth = ref.watch(selectedMonthProvider);
            final accounts = ref.watch(accountProvider).value ?? [];
            final categories = ref.watch(categoryProvider).value ?? [];
            final beneficiaries = ref.watch(beneficiaryProvider).value ?? [];

            final activeExpenses = expensesRaw
                .where((e) => e.endDate == null)
                .toList();

            List<ExpenseModel> displayedExpenses = activeExpenses;

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
                        expense.startDate.day < _filterData.startDay!) {
                      return false;
                    }
                    if (_filterData.endDay != null &&
                        expense.startDate.day > _filterData.endDay!) {
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

            final recurringExpenses = displayedExpenses
                .where((e) {
                  if (e.frequencyEnum == Frequency.oneTime) return false;
                  if (e.frequencyEnum == Frequency.annual) {
                    return e.startDate.month == selectedMonth.month;
                  }
                  return true;
                })
                .toList();
            final oneTimeExpenses = displayedExpenses
                .where((e) =>
                    e.frequencyEnum == Frequency.oneTime &&
                    e.startDate.year == selectedMonth.year &&
                    e.startDate.month == selectedMonth.month)
                .toList();

            final monthlyAmount = recurringExpenses
                .where((e) => e.frequencyEnum == Frequency.monthly)
                .fold<double>(0, (s, e) => s + e.amount);
            final annualAmount = recurringExpenses
                .where((e) => e.frequencyEnum == Frequency.annual)
                .fold<double>(0, (s, e) => s + e.amount);
            final oneTimeAmount = oneTimeExpenses
                .fold<double>(0, (s, e) => s + e.amount);

            final isEmpty = recurringExpenses.isEmpty &&
                oneTimeExpenses.isEmpty &&
                _filterData.isEmpty;

            final items = <_ListItem>[];
            items.add(_ListItem.monthSelector());
            items.add(_ListItem.header(
              displayedExpenses,
              isEmpty,
              monthlyAmount,
              annualAmount,
              oneTimeAmount,
            ));
            items.add(_ListItem.filterChips(categories));

            if (recurringExpenses.isNotEmpty) {
              items.add(_ListItem.sectionTitle(
                'Récurrentes',
                recurringExpenses.length,
              ));
              items.add(_ListItem.expensesGroup(recurringExpenses));
            }

            if (oneTimeExpenses.isNotEmpty) {
              items.add(_ListItem.sectionTitle(
                'Ponctuelles',
                oneTimeExpenses.length,
              ));
              items.add(_ListItem.expensesGroup(oneTimeExpenses));
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                top: 120,
                bottom: 145,
                left: 16,
                right: 16,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                if (item.type == _ListItemType.monthSelector) {
                  return const MonthSelector();
                }

                if (item.type == _ListItemType.header) {
                  return _buildHeaderContainer(
                    context,
                    [...recurringExpenses, ...oneTimeExpenses],
                    isEmpty,
                    item.monthlyAmount ?? 0,
                    item.annualAmount ?? 0,
                    item.oneTimeAmount ?? 0,
                  );
                }

                if (item.type == _ListItemType.filterChips) {
                  return _buildFilterChips(context, item.categories ?? []);
                }

                if (item.type == _ListItemType.sectionTitle) {
                  return _buildSectionTitle(context, item.title!, item.count!);
                }

                return _buildExpensesGroup(
                  context,
                  item.expenses!,
                  accounts,
                  categories,
                  beneficiaries,
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
    double monthlyAmount,
    double annualAmount,
    double oneTimeAmount,
  ) {
    return Column(
      children: [
        ExpensesSummaryCard(
          monthlyAmount: monthlyAmount,
          annualAmount: annualAmount,
          oneTimeAmount: oneTimeAmount,
          transactionCount: displayedExpenses.length,
        ),
        _buildSectionHeader(context),
        if (isEmpty) _buildEmptyState(context),
      ],
    );
  }

  Widget _buildExpensesGroup(
    BuildContext context,
    List<ExpenseModel> expenses,
    List<AccountModel> accounts,
    List<CategoryModel> categories,
    List<Beneficiary> beneficiaries,
  ) {
    return FrostedCard(
      margin: EdgeInsets.zero,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          for (int i = 0; i < expenses.length; i++)
            _buildExpenseRow(
              context,
              expenses[i],
              accounts,
              categories,
              beneficiaries,
              showDivider: i < expenses.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(
    BuildContext context,
    ExpenseModel expense,
    List<AccountModel> accounts,
    List<CategoryModel> categories,
    List<Beneficiary> beneficiaries, {
    required bool showDivider,
  }) {
    final account = accounts.firstWhere(
      (a) => a.id == expense.accountId,
      orElse: () => AccountModel.create(name: 'Compte inconnu', bank: ''),
    );
    final beneficiary = expense.beneficiaryId != null
        ? beneficiaries
            .where((b) => b.id == expense.beneficiaryId)
            .firstOrNull
        : null;
    final category = categories.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () => CategoryModel.create(name: 'Autre', icon: 'category'),
    );

    return ExpenseCard(
      expense: expense,
      accountName: account.name,
      beneficiary: beneficiary,
      category: category,
      showDivider: showDivider,
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
  }

  Widget _buildSectionTitle(BuildContext context, String title, int count) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8, left: 4, right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              height: 14 / 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.09 * 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              height: 14 / 11,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
      BuildContext context, List<CategoryModel> categories) {
    final scheme = Theme.of(context).colorScheme;
    final allSelected = _filterData.categoryIds.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            FrostedChip(
              label: const Text('Tout'),
              selected: allSelected,
              avatar: Icon(
                Icons.filter_list,
                size: 16,
                color: allSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              onPressed: () {
                setState(() {
                  _filterData.categoryIds = const [];
                });
              },
            ),
            ...categories.map((category) {
              final selected = _filterData.categoryIds.contains(category.id);
              final color = Color(category.color);
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: FrostedChip(
                  label: Text(category.name),
                  selected: selected,
                  selectedColor: color,
                  avatar: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: selected ? 0.9 : 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      final ids = List<int>.from(_filterData.categoryIds);
                      if (selected) {
                        ids.remove(category.id);
                      } else {
                        ids.add(category.id);
                      }
                      _filterData.categoryIds = ids;
                    });
                  },
                ),
              );
            }),
          ],
        ),
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
                      FrostedIconButton(
                        icon: Icons.close,
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
                          FrostedIconButton(
                            icon: Icons.search,
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: () {
                              setState(() {
                                _isSearchVisible = true;
                              });
                            },
                          ),
                          FrostedIconButton(
                            icon: Icons.filter_list,
                            color:
                                _filterData.isEmpty
                                    ? Theme.of(context).iconTheme.color
                                    : Theme.of(context).colorScheme.primary,
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
          closedExpenses: ref.read(expenseProvider.notifier).getClosedExpenses(),
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

enum _ListItemType {
  monthSelector,
  header,
  filterChips,
  sectionTitle,
  expensesGroup,
}

class _ListItem {
  final _ListItemType type;
  final List<ExpenseModel>? expenses;
  final bool? isEmpty;
  final String? title;
  final int? count;
  final double? monthlyAmount;
  final double? annualAmount;
  final double? oneTimeAmount;
  final List<CategoryModel>? categories;

  _ListItem._({
    required this.type,
    this.expenses,
    this.isEmpty,
    this.title,
    this.count,
    this.monthlyAmount,
    this.annualAmount,
    this.oneTimeAmount,
    this.categories,
  });

  factory _ListItem.header(
    List<ExpenseModel> expenses,
    bool isEmpty,
    double monthlyAmount,
    double annualAmount,
    double oneTimeAmount,
  ) =>
      _ListItem._(
        type: _ListItemType.header,
        expenses: expenses,
        isEmpty: isEmpty,
        monthlyAmount: monthlyAmount,
        annualAmount: annualAmount,
        oneTimeAmount: oneTimeAmount,
      );

  factory _ListItem.filterChips(List<CategoryModel> categories) =>
      _ListItem._(type: _ListItemType.filterChips, categories: categories);

  factory _ListItem.sectionTitle(String title, int count) =>
      _ListItem._(type: _ListItemType.sectionTitle, title: title, count: count);

  factory _ListItem.expensesGroup(List<ExpenseModel> expenses) =>
      _ListItem._(type: _ListItemType.expensesGroup, expenses: expenses);

  factory _ListItem.monthSelector() =>
      _ListItem._(type: _ListItemType.monthSelector);
}
