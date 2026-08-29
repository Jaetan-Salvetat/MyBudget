import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/layout_insets.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/enums/revenue_group_by.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/providers/revenues_view_provider.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/core/providers/transaction_filter_provider.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/services/revenue_grouping_service.dart';
import 'package:mybudget/core/services/transaction_filter_service.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/models/transaction_filter_data.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/common/empty_state.dart';
import 'package:mybudget/ui/common/widgets/active_filter_pills.dart';
import 'package:mybudget/ui/common/widgets/active_filter_pills_builder.dart';
import 'package:mybudget/ui/common/widgets/transaction_filter_bottom_sheet.dart';
import 'package:mybudget/ui/common/widgets/transaction_search_bar.dart';
import 'package:mybudget/ui/revenues/revenue_queries.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/revenues/widgets/compact_revenue_row.dart';
import 'package:mybudget/ui/revenues/screens/revenue_form_screen.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_group_by_menu.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_group_header.dart';
import 'package:mybudget/ui/revenues/widgets/revenues_quick_filters.dart';
import 'package:mybudget/ui/revenues/widgets/revenues_summary_card.dart';
import 'package:mybudget/ui/settings/beneficiary_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';

class RevenuesList extends ConsumerStatefulWidget {
  const RevenuesList({super.key});
  @override
  ConsumerState<RevenuesList> createState() => _RevenuesListState();
}

class _RevenuesListState extends ConsumerState<RevenuesList> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(revenuesFilterProvider).searchQuery ?? '',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  TransactionFilterNotifier get _filterNotifier =>
      ref.read(revenuesFilterProvider.notifier);

  String? _groupKeyOf(RevenueModel revenue) {
    return ref
        .read(categoryDisplayResolverProvider)
        .value
        ?.groupKeyOrUncategorized(revenue.categorySlug);
  }

  List<RevenueModel> _filterRevenues(
    List<RevenueModel> revenues,
    TransactionFilterData filter,
  ) {
    return TransactionFilterService.apply(
      revenues,
      filter,
      groupKeyOf: _groupKeyOf,
    );
  }

  List<RevenueModel> _monthRevenues() => ref.read(monthRevenuesProvider);

  double _highestAmount(List<RevenueModel> revenues) {
    return revenues.fold<double>(0, (highest, r) => max(highest, r.amount));
  }

  List<ActiveFilterPill> _activeFilterPills(
    TransactionFilterData filter,
    List<CategoryDisplay> categories,
    List<AccountModel> accounts,
    List<Beneficiary> beneficiaries,
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
    final filter = ref.watch(revenuesFilterProvider);
    ref.listen(revenuesFilterProvider, (_, next) {
      _syncSearchController(next.searchQuery ?? '');
    });

    return ref
        .watch(revenueProvider)
        .when(
          loading: () => const Center(child: FrostedCircularProgress()),
          error: (error, _) => Center(child: Text('Erreur: $error')),
          data: (revenues) {
            final axis = ref.watch(revenuesGroupByProvider);
            final accounts = ref.watch(accountProvider).value ?? [];
            final beneficiaries = ref.watch(beneficiaryProvider).value ?? [];
            final resolver = ref.watch(categoryDisplayResolverProvider).value;
            final categories =
                resolver?.groupsOfType(TransactionType.income) ?? const [];

            final visibleRevenues = _filterRevenues(
              ref.watch(monthRevenuesProvider),
              filter,
            );

            final groups = RevenueGroupingService.group(
              visibleRevenues,
              RevenueGroupingService.grouperFor(
                axis,
                categoryResolver: resolver,
                beneficiaries: beneficiaries,
                accounts: accounts,
              ),
            );

            final monthlyRevenues = ref.watch(monthlyRevenuesProvider);

            final pills = _activeFilterPills(
              filter,
              categories,
              accounts,
              beneficiaries,
            );

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                top: 16,
                bottom: mainFlowBottomInset(context),
              ),
              children: [
                _hPad(
                  RevenuesSummaryCard(
                    transactionCount: visibleRevenues.length,
                    monthlyRevenues: monthlyRevenues,
                  ),
                ),
                _hPad(
                  TransactionSearchBar(
                    controller: _searchController,
                    activeFiltersCount: filter.activeCount,
                    badgeColor: context.financeColors.income,
                    hintText: 'Rechercher un revenu, un bénéficiaire…',
                    onChanged: (value) => _filterNotifier.update(
                      (current) => current.copyWith(searchQuery: value),
                    ),
                    onOpenFilters: () => _showFilterBottomSheet(
                      context,
                      categories,
                      accounts,
                      beneficiaries,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                RevenuesQuickFilters(
                  axis: axis,
                  categories: categories,
                  selectedGroupKeys: filter.groupKeys,
                  onOpenGroupBy: () => _openGroupByMenu(axis),
                  onCategoryTap: _filterNotifier.toggleGroup,
                  onClear: _filterNotifier.clearGroups,
                ),
                if (pills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _hPad(
                    ActiveFilterPills(pills: pills, onReset: _resetFilters),
                  ),
                ],
                if (groups.isEmpty) ...[
                  const SizedBox(height: 24),
                  _hPad(_buildEmptyState(context, filter)),
                ],
                for (final group in groups) ...[
                  if (axis == RevenueGroupBy.none)
                    const SizedBox(height: 12)
                  else
                    _hPad(RevenueGroupHeader(group: group, axis: axis)),
                  _hPad(
                    _buildGroup(group.items, accounts, beneficiaries, resolver),
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

  Widget _buildGroup(
    List<RevenueModel> rows,
    List<AccountModel> accounts,
    List<Beneficiary> beneficiaries,
    CategoryDisplayResolver? resolver,
  ) {
    return FrostedCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++)
            _buildRow(
              rows[i],
              accounts,
              beneficiaries,
              resolver,
              showDivider: i < rows.length - 1,
            ),
        ],
      ),
    );
  }

  /// A month other than the one in progress is read : acting on it would mean
  /// deciding what it should retroactively have been.
  bool get _isViewingCurrentMonth {
    final now = DateTime.now();
    final selectedMonth = ref.watch(selectedMonthProvider);
    return now.year == selectedMonth.year && now.month == selectedMonth.month;
  }

  Widget _buildRow(
    RevenueModel revenue,
    List<AccountModel> accounts,
    List<Beneficiary> beneficiaries,
    CategoryDisplayResolver? resolver, {
    required bool showDivider,
  }) {
    final account = accounts.firstWhere(
      (a) => a.id == revenue.accountId,
      orElse: () => AccountModel.create(name: 'Compte inconnu', bank: ''),
    );
    final beneficiary = revenue.beneficiaryId != null
        ? beneficiaries.where((b) => b.id == revenue.beneficiaryId).firstOrNull
        : null;

    final slug = revenue.categorySlug;
    final category = slug == null ? null : resolver?.resolve(slug);

    return CompactRevenueRow(
      revenue: revenue,
      isCurrentMonth: _isViewingCurrentMonth,
      accountName: account.name,
      beneficiary: beneficiary,
      category: category,
      showDivider: showDivider,
      onEdit: () => _openEditScreen(revenue, accounts),
      onDelete: (scope) => _deleteRevenue(revenue, scope),
    );
  }

  Widget _buildEmptyState(BuildContext context, TransactionFilterData filter) {
    final filtered = !filter.isEmpty;
    return EmptyState(
      message: filtered
          ? 'Aucun revenu ne correspond'
          : 'Aucun revenu enregistré',
      subMessage: filtered
          ? 'Ajustez vos filtres pour élargir la recherche'
          : 'Ajoutez vos revenus pour commencer à gérer vos finances',
      icon: Symbols.trending_up_rounded,
      buttonText: filtered ? 'Réinitialiser les filtres' : 'Ajouter un revenu',
      onPressed: () {
        if (filtered) {
          _filterNotifier.clearAll();
          return;
        }
        final accounts = ref.read(accountProvider).value ?? [];
        if (accounts.isEmpty) {
          _showNoAccountDialog(context, 'un revenu');
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

  void _resetFilters() => _filterNotifier.reset();

  void _openGroupByMenu(RevenueGroupBy current) {
    RevenueGroupByMenu.show(
      context: context,
      current: current,
      onSelect: (axis) => ref.read(revenuesGroupByProvider.notifier).set(axis),
    );
  }

  void _showFilterBottomSheet(
    BuildContext context,
    List<CategoryDisplay> categories,
    List<AccountModel> accounts,
    List<Beneficiary> beneficiaries,
  ) {
    TransactionFilterBottomSheet.show(
      context: context,
      title: 'Filtrer les revenus',
      initialFilterData: ref.read(revenuesFilterProvider),
      categories: categories,
      accounts: accounts,
      beneficiaries: beneficiaries,
      highestAmount: _highestAmount(_monthRevenues()),
      resultCount: (filter) => _filterRevenues(_monthRevenues(), filter).length,
      onApply: (updated) => _filterNotifier.update(
        (current) => updated.copyWith(searchQuery: current.searchQuery),
      ),
    );
  }

  Future<void> _openCreateScreen(List<AccountModel> accounts) async {
    final revenue = await RevenueFormScreen.push(
      context: context,
      accounts: accounts,
      closedRevenues: ref.read(revenueProvider.notifier).getClosedRevenues(),
    );
    if (revenue == null) return;

    try {
      await ref.read(revenueProvider.notifier).addRevenue(revenue);
    } catch (e) {
      if (mounted) {
        FrostedSnackbar.show(context, message: 'Erreur lors de l\'ajout: $e');
      }
    }
  }

  Future<void> _openEditScreen(
    RevenueModel revenue,
    List<AccountModel> accounts,
  ) async {
    final updatedRevenue = await RevenueFormScreen.push(
      context: context,
      accounts: accounts,
      revenue: revenue,
    );
    if (updatedRevenue == null) return;

    try {
      await ref.read(revenueProvider.notifier).updateRevenue(updatedRevenue);
    } catch (e) {
      if (mounted) {
        FrostedSnackbar.show(
          context,
          message: 'Erreur lors de la modification: $e',
        );
      }
    }
  }

  Future<void> _deleteRevenue(
    RevenueModel revenue,
    RecurringDeletion scope,
  ) async {
    try {
      await ref
          .read(revenueProvider.notifier)
          .deleteRevenue(revenue.id, scope: scope);
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
