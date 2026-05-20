import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/revenue_filter_data.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/common/empty_state.dart';
import 'package:mybudget/ui/expenses/widgets/expenses_search_bar.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/revenues/widgets/compact_revenue_row.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_bottom_sheet.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_filter_bottom_sheet.dart';
import 'package:mybudget/ui/revenues/widgets/revenues_summary_card.dart';
import 'package:mybudget/ui/settings/beneficiary_provider.dart';

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
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(revenueProvider)
        .when(
          loading:
              () => const Center(child: FrostedCircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erreur: $error')),
          data: (revenues) {
            final selectedMonth = ref.watch(selectedMonthProvider);
            final accounts = ref.watch(accountProvider).value ?? [];
            final beneficiaries = ref.watch(beneficiaryProvider).value ?? [];

            final activeRevenues =
                revenues.where((r) => r.endDate == null).toList();

            final filteredRevenues =
                _filterData.isEmpty
                    ? activeRevenues
                    : revenues
                        .where((r) => _matchesFilter(r, _filterData))
                        .toList();

            final recurringRevenues =
                filteredRevenues.where((r) {
                  if (r.frequencyEnum == Frequency.oneTime) return false;
                  if (r.frequencyEnum == Frequency.annual) {
                    return r.startDate.month == selectedMonth.month;
                  }
                  return true;
                }).toList();
            final oneTimeRevenues =
                filteredRevenues
                    .where(
                      (r) =>
                          r.frequencyEnum == Frequency.oneTime &&
                          r.startDate.year == selectedMonth.year &&
                          r.startDate.month == selectedMonth.month,
                    )
                    .toList();

            final monthlyRevenues =
                ref.read(revenueProvider.notifier).getMonthlyRevenues();
            final displayedCount =
                recurringRevenues.length + oneTimeRevenues.length;
            final isEmpty =
                recurringRevenues.isEmpty && oneTimeRevenues.isEmpty;

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 16, bottom: 145),
              children: [
                _hPad(
                  RevenuesSummaryCard(
                    transactionCount: displayedCount,
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
                const SizedBox(height: 12),
                if (isEmpty) _hPad(_buildEmptyState(context)),
                if (recurringRevenues.isNotEmpty) ...[
                  _hPad(
                    _buildSectionTitle(
                      context,
                      'Récurrents',
                      recurringRevenues.length,
                    ),
                  ),
                  _hPad(
                    _buildGroup(recurringRevenues, accounts, beneficiaries),
                  ),
                ],
                if (oneTimeRevenues.isNotEmpty) ...[
                  _hPad(
                    _buildSectionTitle(
                      context,
                      'Ponctuels',
                      oneTimeRevenues.length,
                    ),
                  ),
                  _hPad(_buildGroup(oneTimeRevenues, accounts, beneficiaries)),
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
    List beneficiaries,
  ) {
    return FrostedCard(
      margin: EdgeInsets.zero,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++)
            _buildRow(
              rows[i],
              accounts,
              beneficiaries,
              showDivider: i < rows.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildRow(
    RevenueModel revenue,
    List<AccountModel> accounts,
    List beneficiaries, {
    required bool showDivider,
  }) {
    final account = accounts.firstWhere(
      (a) => a.id == revenue.accountId,
      orElse: () => AccountModel.create(name: 'Compte inconnu', bank: ''),
    );
    final beneficiary =
        revenue.beneficiaryId != null
            ? beneficiaries
                .where((b) => b.id == revenue.beneficiaryId)
                .firstOrNull
            : null;

    return CompactRevenueRow(
      revenue: revenue,
      accountName: account.name,
      beneficiary: beneficiary,
      showDivider: showDivider,
      onEdit: () => _openEditSheet(revenue, accounts),
      onDelete: () => _deleteRevenue(revenue),
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

  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      message: 'Aucun revenu enregistré',
      subMessage: 'Ajoutez vos revenus pour commencer à gérer vos finances',
      icon: Icons.trending_up,
      buttonText: 'Ajouter un revenu',
      onPressed: () {
        final accounts = ref.read(accountProvider).value ?? [];
        if (accounts.isEmpty) {
          _showNoAccountDialog(context, 'un revenu');
          return;
        }
        RevenueBottomSheet.show(
          context: context,
          accounts: accounts,
          closedRevenues:
              ref.read(revenueProvider.notifier).getClosedRevenues(),
          onSubmit: (newRevenue) async {
            try {
              await ref.read(revenueProvider.notifier).addRevenue(newRevenue);
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

  void _showNoAccountDialog(BuildContext context, String action) {
    FrostedDialog.show(
      context: context,
      barrierDismissible: false,
      title: const Text('Aucun compte disponible'),
      content: Text(
        'Vous devez d\'abord créer un compte avant d\'ajouter $action.',
      ),
      actions: [
        FrostedTextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
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

  Future<void> _openEditSheet(
    RevenueModel revenue,
    List<AccountModel> accounts,
  ) async {
    RevenueBottomSheet.show(
      context: context,
      accounts: accounts,
      revenue: revenue,
      onSubmit: (updatedRevenue) async {
        try {
          await ref
              .read(revenueProvider.notifier)
              .updateRevenue(updatedRevenue);
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
