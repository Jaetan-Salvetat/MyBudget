import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/enums/expense_group_by.dart';
import 'package:mybudget/core/enums/expense_sort_by.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/expenses_view_provider.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_filter_data.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/common/empty_state.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/expenses/widgets/active_filter_pills.dart';
import 'package:mybudget/ui/expenses/widgets/compact_expense_row.dart';
import 'package:mybudget/ui/expenses/widgets/expense_bottom_sheet.dart';
import 'package:mybudget/ui/expenses/widgets/expense_filter_bottom_sheet.dart';
import 'package:mybudget/ui/expenses/widgets/expense_group_header.dart';
import 'package:mybudget/ui/expenses/widgets/expense_sort_menu.dart';
import 'package:mybudget/ui/expenses/widgets/expenses_quick_filters.dart';
import 'package:mybudget/ui/expenses/widgets/expenses_search_bar.dart';
import 'package:mybudget/ui/expenses/widgets/expenses_summary_card.dart';
import 'package:mybudget/ui/expenses/widgets/recurring_summary_card.dart';
import 'package:mybudget/ui/settings/beneficiary_provider.dart';
import 'package:mybudget/ui/settings/category_provider.dart';

class ExpensesList extends ConsumerStatefulWidget {
  final ExpenseFilterData? initialFilter;

  const ExpensesList({super.key, this.initialFilter});

  @override
  ConsumerState<ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends ConsumerState<ExpensesList> {
  late ExpenseFilterData _filterData;
  late TextEditingController _searchController;
  late ExpenseSortBy _sortBy;
  late bool _recurringExpanded;

  @override
  void initState() {
    super.initState();
    _filterData = widget.initialFilter ?? ExpenseFilterData();
    _searchController =
        TextEditingController(text: _filterData.searchQuery ?? '');
    _sortBy = ExpenseSortBy.fromName(PreferencesService.getExpensesSortBy());
    _recurringExpanded = PreferencesService.getExpensesRecurringExpanded();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesFilter(ExpenseModel expense, ExpenseFilterData filter) {
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      if (!expense.name
          .toLowerCase()
          .contains(filter.searchQuery!.toLowerCase())) {
        return false;
      }
    }
    if (filter.minAmount != null && expense.amount < filter.minAmount!) {
      return false;
    }
    if (filter.maxAmount != null && expense.amount > filter.maxAmount!) {
      return false;
    }
    if (filter.categoryIds.isNotEmpty &&
        !filter.categoryIds.contains(expense.categoryId)) {
      return false;
    }
    if (filter.accountIds.isNotEmpty &&
        !filter.accountIds.contains(expense.accountId)) {
      return false;
    }
    if (filter.types.isNotEmpty &&
        !filter.types.contains(expense.frequencyEnum)) {
      return false;
    }
    return true;
  }

  List<ExpenseModel> _filterExpenses(
      List<ExpenseModel> expenses, ExpenseFilterData filter) {
    return expenses.where((e) => _matchesFilter(e, filter)).toList();
  }

  bool _belongsToSelectedMonth(ExpenseModel expense, DateTime selectedMonth) {
    switch (expense.frequencyEnum) {
      case Frequency.monthly:
        return true;
      case Frequency.annual:
        return expense.startDate.month == selectedMonth.month;
      case Frequency.oneTime:
        return expense.startDate.year == selectedMonth.year &&
            expense.startDate.month == selectedMonth.month;
    }
  }

  DateTime _effectiveDate(ExpenseModel expense, DateTime selectedMonth) {
    switch (expense.frequencyEnum) {
      case Frequency.monthly:
        return DateTime(
          selectedMonth.year,
          selectedMonth.month,
          expense.startDate.day,
        );
      case Frequency.annual:
        return DateTime(
          selectedMonth.year,
          expense.startDate.month,
          expense.startDate.day,
        );
      case Frequency.oneTime:
        return expense.startDate;
    }
  }

  ExpenseModel _withEffectiveDate(
      ExpenseModel expense, DateTime selectedMonth) {
    final effective = _effectiveDate(expense, selectedMonth);
    if (effective.year == expense.startDate.year &&
        effective.month == expense.startDate.month &&
        effective.day == expense.startDate.day) {
      return expense;
    }
    return expense.copyWith(startDate: effective);
  }

  List<ActiveFilterPill> _activeFilterPills(
      List<CategoryModel> categories, List<AccountModel> accounts) {
    final pills = <ActiveFilterPill>[];

    for (final type in _filterData.types) {
      final label = switch (type) {
        Frequency.monthly => 'Mensuel',
        Frequency.annual => 'Annuel',
        Frequency.oneTime => 'Ponctuel',
      };
      pills.add(ActiveFilterPill(
        id: 'type-${type.name}',
        label: label,
        onRemove: () {
          setState(() {
            _filterData = _filterData.copyWith(
              types: _filterData.types.where((t) => t != type).toList(),
            );
          });
        },
      ));
    }

    for (final id in _filterData.categoryIds) {
      final cat = categories.firstWhere(
        (c) => c.id == id,
        orElse: () => CategoryModel.create(name: '—', icon: 'category'),
      );
      pills.add(ActiveFilterPill(
        id: 'cat-$id',
        label: cat.name,
        onRemove: () {
          setState(() {
            _filterData = _filterData.copyWith(
              categoryIds:
                  _filterData.categoryIds.where((c) => c != id).toList(),
            );
          });
        },
      ));
    }

    for (final id in _filterData.accountIds) {
      final acc = accounts.firstWhere(
        (a) => a.id == id,
        orElse: () => AccountModel.create(name: '—', bank: ''),
      );
      pills.add(ActiveFilterPill(
        id: 'acc-$id',
        label: acc.name,
        onRemove: () {
          setState(() {
            _filterData = _filterData.copyWith(
              accountIds:
                  _filterData.accountIds.where((a) => a != id).toList(),
            );
          });
        },
      ));
    }

    if (_filterData.minAmount != null || _filterData.maxAmount != null) {
      final min = _filterData.minAmount?.round();
      final max = _filterData.maxAmount?.round();
      String label;
      if (min != null && max != null) {
        label = '$min – $max €';
      } else if (min != null) {
        label = '≥ $min €';
      } else {
        label = '≤ $max €';
      }
      pills.add(ActiveFilterPill(
        id: 'amount',
        label: label,
        onRemove: () {
          setState(() {
            _filterData = _filterData.copyWith(
              minAmount: null,
              maxAmount: null,
            );
          });
        },
      ));
    }

    return pills;
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(expenseProvider).when(
          loading: () =>
              const Center(child: FrostedCircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erreur: $error')),
          data: (expensesRaw) {
            final selectedMonth = ref.watch(selectedMonthProvider);
            final groupBy = ref.watch(expensesGroupByProvider);
            final accounts = ref.watch(accountProvider).value ?? [];
            final categories = ref.watch(categoryProvider).value ?? [];
            final beneficiaries = ref.watch(beneficiaryProvider).value ?? [];

            final activeExpenses = expensesRaw
                .where((e) => e.endDate == null)
                .where((e) => _belongsToSelectedMonth(e, selectedMonth))
                .map((e) => _withEffectiveDate(e, selectedMonth))
                .toList();

            final filteredExpenses =
                _filterExpenses(activeExpenses, _filterData);

            final recurring = filteredExpenses
                .where((e) => e.frequencyEnum != Frequency.oneTime)
                .toList();
            final oneTime = filteredExpenses
                .where((e) => e.frequencyEnum == Frequency.oneTime)
                .toList();

            final sortedOneTime = _sortBy.apply(oneTime);
            final sortedRecurring = _sortBy.apply(recurring);

            final descending = _sortBy != ExpenseSortBy.dateAsc;
            final dayGroups = groupBy == ExpenseGroupBy.day
                ? ExpenseGroupingService.groupByDay(sortedOneTime,
                    descending: descending)
                : null;
            final weekGroups = groupBy == ExpenseGroupBy.week
                ? ExpenseGroupingService.groupByWeek(
                    sortedOneTime,
                    selectedMonth,
                    descending: descending,
                  )
                : null;

            final weeklyBars = ExpenseGroupingService.weeklyTotals(
              filteredExpenses,
              selectedMonth,
            );

            final total =
                filteredExpenses.fold<double>(0, (s, e) => s + e.amount);
            final pills = _activeFilterPills(categories, accounts);

            final today = DateTime.now();
            final isViewingCurrentMonth = today.year == selectedMonth.year &&
                today.month == selectedMonth.month;

            final isEmpty = filteredExpenses.isEmpty && _filterData.isEmpty;

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                top: 16,
                bottom: 145,
                left: 16,
                right: 16,
              ),
              children: [
                ExpensesSummaryCard(
                  total: total,
                  filteredCount: filteredExpenses.length,
                  totalCount: activeExpenses.length,
                  weeklyTotals: weeklyBars,
                ),
                ExpensesSearchBar(
                  controller: _searchController,
                  activeFiltersCount: _filterData.activeCount,
                  onChanged: (value) {
                    setState(() {
                      _filterData =
                          _filterData.copyWith(searchQuery: value);
                    });
                  },
                  onOpenFilters: () =>
                      _showFilterSheet(context, categories, accounts),
                ),
                const SizedBox(height: 10),
                ExpensesQuickFilters(
                  categories: categories,
                  selectedCategoryIds: _filterData.categoryIds,
                  sortBy: _sortBy,
                  onOpenSort: _openSortMenu,
                  onCategoryTap: _toggleCategoryFilter,
                ),
                if (pills.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ActiveFilterPills(pills: pills, onReset: _resetFilters),
                ],
                if (isEmpty) ...[
                  const SizedBox(height: 24),
                  _buildEmptyState(context),
                ],
                if (sortedRecurring.isNotEmpty)
                  RecurringSummaryCard(
                    count: sortedRecurring.length,
                    total: sortedRecurring.fold<double>(
                      0,
                      (s, e) => s + e.amount,
                    ),
                    expanded: _recurringExpanded,
                    onToggle: _toggleRecurringExpanded,
                    expandedContent: _recurringExpanded
                        ? _buildRecurringRows(
                            sortedRecurring, categories, beneficiaries)
                        : null,
                  ),
                if (dayGroups != null)
                  for (final group in dayGroups) ...[
                    ExpenseDayHeader(
                      date: group.date,
                      count: group.items.length,
                      total: group.total,
                      isToday: isViewingCurrentMonth &&
                          group.date.day == today.day,
                    ),
                    FrostedCard(
                      margin: EdgeInsets.zero,
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 2),
                      child: Column(
                        children: [
                          for (int i = 0; i < group.items.length; i++)
                            _buildRow(
                              group.items[i],
                              categories,
                              beneficiaries,
                              showDivider: i < group.items.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ],
                if (weekGroups != null)
                  for (final group in weekGroups) ...[
                    ExpenseWeekHeader(
                      weekNumber: group.weekNumber,
                      weekStart: group.weekStart,
                      weekEnd: group.weekEnd,
                      count: group.items.length,
                      total: group.total,
                    ),
                    FrostedCard(
                      margin: EdgeInsets.zero,
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 2),
                      child: Column(
                        children: [
                          for (int i = 0; i < group.items.length; i++)
                            _buildRow(
                              group.items[i],
                              categories,
                              beneficiaries,
                              showDivider: i < group.items.length - 1,
                              showDate: true,
                            ),
                        ],
                      ),
                    ),
                  ],
                const SizedBox(height: 12),
              ],
            );
          },
        );
  }

  Widget _buildRecurringRows(
    List<ExpenseModel> rows,
    List<CategoryModel> categories,
    List<Beneficiary> beneficiaries,
  ) {
    return Column(
      children: [
        for (int i = 0; i < rows.length; i++)
          _buildRow(
            rows[i],
            categories,
            beneficiaries,
            showDivider: i < rows.length - 1,
          ),
      ],
    );
  }

  Widget _buildRow(
    ExpenseModel expense,
    List<CategoryModel> categories,
    List<Beneficiary> beneficiaries, {
    required bool showDivider,
    bool showDate = false,
  }) {
    final category = categories.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () => CategoryModel.create(name: 'Autre', icon: 'category'),
    );
    final beneficiary = expense.beneficiaryId != null
        ? beneficiaries
            .where((b) => b.id == expense.beneficiaryId)
            .firstOrNull
        : null;

    return CompactExpenseRow(
      expense: expense,
      category: category,
      beneficiary: beneficiary,
      showDivider: showDivider,
      showDate: showDate,
      onEdit: () => _openEditSheet(expense),
      onDelete: () => _deleteExpense(expense),
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
          closedExpenses:
              ref.read(expenseProvider.notifier).getClosedExpenses(),
          onSubmit: (newExpense) async {
            try {
              await ref.read(expenseProvider.notifier).addExpense(newExpense);
            } catch (e) {
              if (context.mounted) {
                FrostedSnackbar.show(
                  context,
                  message: 'Erreur lors de l\'ajout: $e',
                );
              }
            }
          },
          onCancel: () {},
        );
      },
    );
  }

  void _toggleCategoryFilter(int? id) {
    setState(() {
      if (id == null) {
        _filterData = _filterData.copyWith(categoryIds: const []);
      } else {
        final ids = List<int>.from(_filterData.categoryIds);
        if (ids.contains(id)) {
          ids.remove(id);
        } else {
          ids.add(id);
        }
        _filterData = _filterData.copyWith(categoryIds: ids);
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _filterData = ExpenseFilterData(
        searchQuery: _filterData.searchQuery,
      );
    });
  }

  Future<void> _toggleRecurringExpanded() async {
    final next = !_recurringExpanded;
    setState(() => _recurringExpanded = next);
    await PreferencesService.setExpensesRecurringExpanded(next);
  }

  Future<void> _openSortMenu() async {
    ExpenseSortMenu.show(
      context: context,
      current: _sortBy,
      onSelect: (option) async {
        setState(() => _sortBy = option);
        await PreferencesService.setExpensesSortBy(option.name);
      },
    );
  }

  void _showFilterSheet(
    BuildContext context,
    List<CategoryModel> categories,
    List<AccountModel> accounts,
  ) {
    ExpenseFilterBottomSheet.show(
      context: context,
      initialFilterData: _filterData,
      categories: categories,
      accounts: accounts,
      resultCount: (filter) {
        final selectedMonth = ref.read(selectedMonthProvider);
        final activeExpenses = (ref.read(expenseProvider).value ?? [])
            .where((e) => e.endDate == null)
            .where((e) => _belongsToSelectedMonth(e, selectedMonth))
            .toList();
        return _filterExpenses(activeExpenses, filter).length;
      },
      onApply: (updated) {
        setState(() {
          _filterData = updated.copyWith(searchQuery: _filterData.searchQuery);
        });
      },
      onClear: () {},
      onCancel: () {},
    );
  }

  Future<void> _openEditSheet(ExpenseModel expense) async {
    final accounts = ref.read(accountProvider).value ?? [];
    final categories = ref.read(categoryProvider).value ?? [];
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
          if (mounted) {
            FrostedSnackbar.show(
              context,
              message: 'Erreur lors de la modification: $e',
            );
          }
        }
      },
      onCancel: () {},
    );
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    try {
      await ref.read(expenseProvider.notifier).deleteExpense(expense.id);
    } catch (e) {
      if (mounted) {
        FrostedSnackbar.show(
          context,
          message: 'Erreur lors de la suppression: $e',
        );
      }
    }
  }
}
