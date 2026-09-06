import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/constants/layout_insets.dart';
import 'package:mybudget/core/enums/effective_month.dart';
import 'package:mybudget/core/enums/expense_group_by.dart';
import 'package:mybudget/core/enums/expense_sort_by.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/values/category_display.dart';
import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/data/model/beneficiary_model.dart';
import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/model/transaction_filter_data.dart';
import 'package:mybudget/data/provider/accounts_provider.dart';
import 'package:mybudget/data/provider/beneficiary_provider.dart';
import 'package:mybudget/data/provider/category_override_provider.dart';
import 'package:mybudget/data/provider/expenses_provider.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/service/category_display_resolver.dart';
import 'package:mybudget/data/service/preferences_service.dart';
import 'package:mybudget/data/service/transaction_filter_service.dart';
import 'package:mybudget/ui/common/empty_state.dart';
import 'package:mybudget/ui/common/widgets/active_filter_pills.dart';
import 'package:mybudget/ui/common/widgets/active_filter_pills_builder.dart';
import 'package:mybudget/ui/common/widgets/recurring_edit_scope_dialog.dart';
import 'package:mybudget/ui/common/widgets/transaction_filter_bottom_sheet.dart';
import 'package:mybudget/ui/common/widgets/transaction_search_bar.dart';
import 'package:mybudget/ui/expenses/screens/expense_form_screen.dart';
import 'package:mybudget/ui/expenses/widgets/compact_expense_row.dart';
import 'package:mybudget/ui/expenses/widgets/expense_group_header.dart';
import 'package:mybudget/ui/expenses/widgets/expense_sort_menu.dart';
import 'package:mybudget/ui/expenses/widgets/expenses_quick_filters.dart';
import 'package:mybudget/ui/expenses/widgets/expenses_summary_card.dart';
import 'package:mybudget/ui/expenses/widgets/recurring_summary_card.dart';
import 'package:mybudget/ui/shared/expense_queries.dart';
import 'package:mybudget/ui/shared/expenses_view_provider.dart';
import 'package:mybudget/ui/shared/selected_month_provider.dart';
import 'package:mybudget/ui/shared/transaction_filter_provider.dart';
import 'package:mybudget/ui/transaction_details/screens/expense_details_screen.dart';

class ExpensesList extends ConsumerStatefulWidget {
  const ExpensesList({super.key});

  @override
  ConsumerState<ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends ConsumerState<ExpensesList> {
  late TextEditingController _searchController;
  late ExpenseSortBy _sortBy;
  late bool _recurringExpanded;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(expensesFilterProvider).searchQuery ?? '',
    );
    _sortBy = ExpenseSortBy.fromName(PreferencesService.getExpensesSortBy());
    _recurringExpanded = false;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  TransactionFilterNotifier get _filterNotifier =>
      ref.read(expensesFilterProvider.notifier);

  String? _groupKeyOf(ExpenseModel expense) {
    return ref
        .read(categoryDisplayResolverProvider)
        .value
        ?.groupKeyOrUncategorized(expense.categorySlug);
  }

  List<ExpenseModel> _monthExpenses() => ref.read(monthExpensesProvider);

  double _highestAmount(List<ExpenseModel> expenses) {
    return expenses.fold<double>(0, (highest, e) => max(highest, e.amount));
  }

  List<ExpenseModel> _filterExpenses(
    List<ExpenseModel> expenses,
    TransactionFilterData filter,
  ) {
    return TransactionFilterService.apply(
      expenses,
      filter,
      groupKeyOf: _groupKeyOf,
    );
  }

  List<ActiveFilterPill> _activeFilterPills(
    TransactionFilterData filter,
    List<CategoryDisplay> categories,
    List<AccountModel> accounts,
    List<BeneficiaryModel> beneficiaries,
  ) {
    return ActiveFilterPillsBuilder.build(
      filter: filter,
      categories: categories,
      accounts: accounts,
      beneficiaries: beneficiaries,
      onChanged: (updated) => _filterNotifier.update((_) => updated),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(expensesFilterProvider);
    ref.listen(expensesFilterProvider, (_, next) {
      _syncSearchController(next.searchQuery ?? '');
    });

    return ref
        .watch(expenseProvider)
        .when(
          loading: () => const Center(child: FrostedCircularProgress()),
          error: (error, _) => Center(child: Text('Erreur: $error')),
          data: (expensesRaw) {
            final selectedMonth = ref.watch(selectedMonthProvider);
            final groupBy = ref.watch(expensesGroupByProvider);
            final accounts = ref.watch(accountProvider);
            final resolver = ref.watch(categoryDisplayResolverProvider).value;
            final categories =
                resolver?.groupsOfType(TransactionType.expense) ?? const [];
            final beneficiaries = ref.watch(beneficiaryProvider).value ?? [];

            final monthExpenses = ref.watch(monthExpensesProvider);
            final filteredExpenses = _filterExpenses(monthExpenses, filter);

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
                ? ExpenseGroupingService.groupByDay(
                    sortedOneTime,
                    descending: descending,
                  )
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

            final total = filteredExpenses.fold<double>(
              0,
              (s, e) => s + e.amount,
            );
            final pills = _activeFilterPills(
              filter,
              categories,
              accounts,
              beneficiaries,
            );

            final today = ref.read(clockProvider)();
            final isViewingCurrentMonth = _isViewingCurrentMonth;

            final isEmpty = filteredExpenses.isEmpty && filter.isEmpty;

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                top: 16,
                bottom: mainFlowBottomInset(context),
              ),
              children: [
                _hPad(
                  ExpensesSummaryCard(
                    total: total,
                    filteredCount: filteredExpenses.length,
                    totalCount: monthExpenses.length,
                    weeklyTotals: weeklyBars,
                  ),
                ),
                _hPad(
                  TransactionSearchBar(
                    controller: _searchController,
                    activeFiltersCount: filter.activeCount,
                    onChanged: (value) => _filterNotifier.update(
                      (current) => current.copyWith(searchQuery: value),
                    ),
                    onOpenFilters: () => _showFilterSheet(
                      context,
                      categories,
                      accounts,
                      beneficiaries,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ExpensesQuickFilters(
                  categories: categories,
                  selectedGroupKeys: filter.groupKeys,
                  sortBy: _sortBy,
                  onOpenSort: _openSortMenu,
                  onCategoryTap: _toggleCategoryFilter,
                ),
                const SizedBox(height: 12),
                if (pills.isNotEmpty) ...[
                  _hPad(
                    ActiveFilterPills(pills: pills, onReset: _resetFilters),
                  ),
                  const SizedBox(height: 12),
                ],
                if (isEmpty) ...[
                  const SizedBox(height: 12),
                  _hPad(_buildEmptyState(context)),
                ],
                if (sortedRecurring.isNotEmpty)
                  _hPad(
                    RecurringSummaryCard(
                      count: sortedRecurring.length,
                      total: sortedRecurring.fold<double>(
                        0,
                        (s, e) => s + e.amount,
                      ),
                      expanded: _recurringExpanded,
                      onToggle: _toggleRecurringExpanded,
                      expandedContent: _buildRecurringRows(
                        sortedRecurring,
                        resolver,
                        beneficiaries,
                      ),
                    ),
                  ),
                if (dayGroups != null)
                  for (final group in dayGroups) ...[
                    _hPad(
                      ExpenseDayHeader(
                        date: group.date,
                        count: group.items.length,
                        total: group.total,
                        isToday:
                            isViewingCurrentMonth &&
                            group.date.day == today.day,
                      ),
                    ),
                    _hPad(
                      FrostedCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < group.items.length; i++)
                              _buildRow(
                                group.items[i],
                                resolver,
                                beneficiaries,
                                showDivider: i < group.items.length - 1,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                if (weekGroups != null)
                  for (final group in weekGroups) ...[
                    _hPad(
                      ExpenseWeekHeader(
                        weekNumber: group.weekNumber,
                        weekStart: group.weekStart,
                        weekEnd: group.weekEnd,
                        count: group.items.length,
                        total: group.total,
                      ),
                    ),
                    _hPad(
                      FrostedCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < group.items.length; i++)
                              _buildRow(
                                group.items[i],
                                resolver,
                                beneficiaries,
                                showDivider: i < group.items.length - 1,
                                showDate: true,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                const SizedBox(height: 12),
              ],
            );
          },
        );
  }

  Widget _hPad(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kMainFlowGutter),
      child: child,
    );
  }

  Widget _buildRecurringRows(
    List<ExpenseModel> rows,
    CategoryDisplayResolver? resolver,
    List<BeneficiaryModel> beneficiaries,
  ) {
    return Column(
      children: [
        for (int i = 0; i < rows.length; i++)
          _buildRow(
            rows[i],
            resolver,
            beneficiaries,
            showDivider: i < rows.length - 1,
          ),
      ],
    );
  }

  bool get _isViewingCurrentMonth {
    final now = ref.read(clockProvider)();
    final selectedMonth = ref.watch(selectedMonthProvider);
    return now.year == selectedMonth.year && now.month == selectedMonth.month;
  }

  Widget _buildRow(
    ExpenseModel expense,
    CategoryDisplayResolver? resolver,
    List<BeneficiaryModel> beneficiaries, {
    required bool showDivider,
    bool showDate = false,
  }) {
    final slug = expense.categorySlug;
    final category = slug == null ? null : resolver?.resolve(slug);
    final beneficiary = expense.beneficiaryId != null
        ? beneficiaries.where((b) => b.id == expense.beneficiaryId).firstOrNull
        : null;

    return CompactExpenseRow(
      expense: expense,
      isCurrentMonth: _isViewingCurrentMonth,
      now: ref.read(clockProvider)(),
      category: category,
      beneficiary: beneficiary,
      showDivider: showDivider,
      showDate: showDate,
      onOpen: () => ExpenseDetailsScreen.push(
        context: context,
        expenseId: expense.id,
        isCurrentMonth: _isViewingCurrentMonth,
      ),
      onEdit: () => _openEditScreen(expense),
      onDelete: (scope) => _deleteExpense(expense, scope),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      message: 'Aucune dépense enregistrée',
      subMessage: 'Ajoutez vos dépenses pour commencer à gérer vos finances',
      icon: Symbols.receipt_long_rounded,
      buttonText: 'Ajouter une dépense',
      onPressed: () {
        final accounts = ref.read(accountProvider);
        if (accounts.isEmpty) {
          _showNoAccountDialog(context, 'une dépense');
          return;
        }
        _openCreateScreen(accounts);
      },
    );
  }

  void _showNoAccountDialog(BuildContext context, String action) {
    showFrostedDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FrostedDialog(
        title: 'Aucun compte disponible',
        body: Text(
          'Vous devez d\'abord créer un compte avant d\'ajouter $action.',
        ),
        actions: [
          FrostedButton.text(
            label: 'OK',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _syncSearchController(String searchQuery) {
    if (_searchController.text == searchQuery) return;
    _searchController.value = TextEditingValue(
      text: searchQuery,
      selection: TextSelection.collapsed(offset: searchQuery.length),
    );
  }

  void _toggleCategoryFilter(String? id) {
    if (id == null) {
      _filterNotifier.clearGroups();
      return;
    }
    _filterNotifier.toggleGroup(id);
  }

  void _resetFilters() => _filterNotifier.reset();

  void _toggleRecurringExpanded() {
    setState(() => _recurringExpanded = !_recurringExpanded);
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
    List<CategoryDisplay> categories,
    List<AccountModel> accounts,
    List<BeneficiaryModel> beneficiaries,
  ) {
    TransactionFilterBottomSheet.show(
      context: context,
      title: 'Filtrer les dépenses',
      initialFilterData: ref.read(expensesFilterProvider),
      categories: categories,
      accounts: accounts,
      beneficiaries: beneficiaries,
      highestAmount: _highestAmount(_monthExpenses()),
      resultCount: (filter) => _filterExpenses(_monthExpenses(), filter).length,
      onApply: (updated) => _filterNotifier.update(
        (current) => updated.copyWith(searchQuery: current.searchQuery),
      ),
    );
  }

  Future<void> _openCreateScreen(List<AccountModel> accounts) async {
    final expense = await ExpenseFormScreen.push(
      context: context,
      accounts: accounts,
      closedExpenses: ref.read(expenseProvider.notifier).getClosedExpenses(),
    );
    if (expense == null) return;

    try {
      await ref.read(expenseProvider.notifier).addExpense(expense);
    } catch (e) {
      if (mounted) {
        FrostedSnackbar.show(context, message: 'Erreur lors de l\'ajout: $e');
      }
    }
  }

  Future<void> _openEditScreen(ExpenseModel expense) async {
    final updatedExpense = await ExpenseFormScreen.push(
      context: context,
      accounts: ref.read(accountProvider),
      expense: expense,
    );
    if (updatedExpense == null || !mounted) return;

    await RecurringEditScopeDialog.submit(
      context: context,
      before: expense,
      after: updatedExpense,
      now: ref.read(clockProvider)(),
      onConfirmed: (effectiveMonth) =>
          _saveExpense(updatedExpense, effectiveMonth: effectiveMonth),
    );
  }

  Future<void> _saveExpense(
    ExpenseModel expense, {
    required EffectiveMonth? effectiveMonth,
  }) async {
    try {
      await ref
          .read(expenseProvider.notifier)
          .updateExpense(expense, effectiveMonth: effectiveMonth);
    } catch (e) {
      if (mounted) {
        FrostedSnackbar.show(
          context,
          message: 'Erreur lors de la modification: $e',
        );
      }
    }
  }

  Future<void> _deleteExpense(
    ExpenseModel expense,
    RecurringDeletion scope,
  ) async {
    try {
      await ref
          .read(expenseProvider.notifier)
          .deleteExpense(expense.id, scope: scope);
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
