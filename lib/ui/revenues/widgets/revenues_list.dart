import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/layout_insets.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/revenue_group_by.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/providers/revenues_view_provider.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/services/revenue_grouping_service.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/revenue_filter_data.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/common/empty_state.dart';
import 'package:mybudget/ui/expenses/widgets/expenses_search_bar.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/revenues/widgets/compact_revenue_row.dart';
import 'package:mybudget/ui/revenues/screens/revenue_form_screen.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_filter_bottom_sheet.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_group_by_menu.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_group_header.dart';
import 'package:mybudget/ui/revenues/widgets/revenues_quick_filters.dart';
import 'package:mybudget/ui/revenues/widgets/revenues_summary_card.dart';
import 'package:mybudget/ui/settings/beneficiary_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';

class RevenuesList extends ConsumerStatefulWidget {
  const RevenuesList({super.key});
  @override
  ConsumerState<RevenuesList> createState() => _RevenuesListState();
}

class _RevenuesListState extends ConsumerState<RevenuesList> {
  RevenueFilterData _filterData = RevenueFilterData();
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: _filterData.searchQuery ?? '',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesFilter(RevenueModel revenue, RevenueFilterData filter) {
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      if (!revenue.name.toLowerCase().contains(
        filter.searchQuery!.toLowerCase(),
      )) {
        return false;
      }
    }
    if (filter.minAmount != null && revenue.amount < filter.minAmount!) {
      return false;
    }
    if (filter.maxAmount != null && revenue.amount > filter.maxAmount!) {
      return false;
    }
    if (filter.accountIds.isNotEmpty &&
        !filter.accountIds.contains(revenue.accountId)) {
      return false;
    }
    if (filter.beneficiaryIds.isNotEmpty &&
        !filter.beneficiaryIds.contains(revenue.beneficiaryId)) {
      return false;
    }
    if (filter.frequencies.isNotEmpty &&
        !filter.frequencies.contains(revenue.frequency)) {
      return false;
    }
    if (filter.categoryGroupKeys.isNotEmpty &&
        !filter.categoryGroupKeys.contains(_groupKeyOf(revenue))) {
      return false;
    }
    return true;
  }

  String? _groupKeyOf(RevenueModel revenue) {
    return ref
        .read(categoryDisplayResolverProvider)
        .value
        ?.groupKeyOrUncategorized(revenue.categorySlug);
  }

  bool _belongsToSelectedMonth(RevenueModel revenue, DateTime selectedMonth) {
    switch (revenue.frequencyEnum) {
      case Frequency.monthly:
        return true;
      case Frequency.annual:
        return revenue.startDate.month == selectedMonth.month;
      case Frequency.oneTime:
        return revenue.startDate.year == selectedMonth.year &&
            revenue.startDate.month == selectedMonth.month;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(revenueProvider)
        .when(
          loading: () => const Center(child: FrostedCircularProgress()),
          error: (error, _) => Center(child: Text('Erreur: $error')),
          data: (revenues) {
            final selectedMonth = ref.watch(selectedMonthProvider);
            final axis = ref.watch(revenuesGroupByProvider);
            final accounts = ref.watch(accountProvider).value ?? [];
            final beneficiaries = ref.watch(beneficiaryProvider).value ?? [];
            final resolver = ref.watch(categoryDisplayResolverProvider).value;
            final categories =
                resolver?.groupsOfType(TransactionType.income) ?? const [];

            final visibleRevenues = revenues
                .where((r) => r.endDate == null)
                .where((r) => _belongsToSelectedMonth(r, selectedMonth))
                .where((r) => _matchesFilter(r, _filterData))
                .toList();

            final groups = RevenueGroupingService.group(
              visibleRevenues,
              RevenueGroupingService.grouperFor(
                axis,
                categoryResolver: resolver,
                beneficiaries: beneficiaries,
                accounts: accounts,
              ),
            );

            final monthlyRevenues = ref
                .read(revenueProvider.notifier)
                .getMonthlyRevenues();

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
                  ExpensesSearchBar(
                    controller: _searchController,
                    activeFiltersCount: _filterData.activeCount,
                    hintText: 'Rechercher un revenu, un bénéficiaire…',
                    onChanged: (value) {
                      setState(() {
                        _filterData.searchQuery = value;
                      });
                    },
                    onOpenFilters: () => _showFilterBottomSheet(context),
                  ),
                ),
                const SizedBox(height: 10),
                RevenuesQuickFilters(
                  axis: axis,
                  categories: categories,
                  selectedGroupKeys: _filterData.categoryGroupKeys,
                  onOpenGroupBy: () => _openGroupByMenu(axis),
                  onCategoryTap: _toggleCategoryFilter,
                  onClear: _clearCategoryFilter,
                ),
                if (groups.isEmpty) ...[
                  const SizedBox(height: 24),
                  _hPad(_buildEmptyState(context)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      accountName: account.name,
      beneficiary: beneficiary,
      category: category,
      showDivider: showDivider,
      onEdit: () => _openEditScreen(revenue, accounts),
      onDelete: () => _deleteRevenue(revenue),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final filtered = !_filterData.isEmpty;
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
          setState(() {
            _filterData = RevenueFilterData();
            _searchController.clear();
          });
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

  void _toggleCategoryFilter(String groupKey) {
    final groupKeys = List<String>.from(_filterData.categoryGroupKeys);
    if (!groupKeys.remove(groupKey)) groupKeys.add(groupKey);
    setState(() {
      _filterData.categoryGroupKeys = groupKeys;
    });
  }

  void _clearCategoryFilter() {
    setState(() {
      _filterData.categoryGroupKeys = const [];
    });
  }

  void _openGroupByMenu(RevenueGroupBy current) {
    RevenueGroupByMenu.show(
      context: context,
      current: current,
      onSelect: (axis) => ref.read(revenuesGroupByProvider.notifier).set(axis),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final accounts = ref.read(accountProvider).value ?? [];
    final beneficiaries = ref.read(beneficiaryProvider).value ?? [];
    RevenueFilterBottomSheet.show(
      context: context,
      initialFilterData: _filterData,
      accounts: accounts,
      beneficiaries: beneficiaries,
      onApply: (updatedFilterData) {
        setState(() {
          _filterData = updatedFilterData;
        });
      },
      onClear: () {
        setState(() {
          _filterData = RevenueFilterData();
        });
      },
      onCancel: () {},
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

  Future<void> _deleteRevenue(RevenueModel revenue) async {
    try {
      await ref.read(revenueProvider.notifier).deleteRevenue(revenue.id);
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
