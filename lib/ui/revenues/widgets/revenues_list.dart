import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/models/revenue_filter_data.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/settings/beneficiary_provider.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_bottom_sheet.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_card.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_filter_bottom_sheet.dart';
import 'package:mybudget/ui/revenues/widgets/revenues_summary_card.dart';
import 'package:mybudget/ui/common/empty_state.dart';

class RevenuesList extends ConsumerStatefulWidget {
  const RevenuesList({super.key});
  @override
  ConsumerState<RevenuesList> createState() => _RevenuesListState();
}

class _RevenuesListState extends ConsumerState<RevenuesList> {
  RevenueFilterData _filterData = RevenueFilterData();
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
        .watch(revenueProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erreur: $error')),
          data: (revenues) {
            final accounts = ref.watch(accountProvider).value ?? [];
            final beneficiaries = ref.watch(beneficiaryProvider).value ?? [];

            List<RevenueModel> filteredRevenues = revenues;

            if (!_filterData.isEmpty) {
              filteredRevenues =
                  revenues.where((revenue) {
                    if (_filterData.searchQuery != null &&
                        _filterData.searchQuery!.isNotEmpty &&
                        !revenue.name.toLowerCase().contains(
                          _filterData.searchQuery!.toLowerCase(),
                        )) {
                      return false;
                    }
                    if (_filterData.minAmount != null &&
                        revenue.amount < _filterData.minAmount!) {
                      return false;
                    }
                    if (_filterData.maxAmount != null &&
                        revenue.amount > _filterData.maxAmount!) {
                      return false;
                    }
                    if (_filterData.accountIds.isNotEmpty &&
                        !_filterData.accountIds.contains(revenue.accountId)) {
                      return false;
                    }
                    if (_filterData.beneficiaryIds.isNotEmpty &&
                        !_filterData.beneficiaryIds.contains(
                          revenue.beneficiaryId,
                        )) {
                      return false;
                    }
                    return true;
                  }).toList();
            }

            final now = DateTime.now();
            final startOfMonth = DateTime(now.year, now.month, 1);

            final activeRevenues =
                filteredRevenues.where((r) {
                  if (r.isRegular) return true;
                  final rDate = DateTime(r.date.year, r.date.month, r.date.day);
                  return !rDate.isBefore(startOfMonth);
                }).toList();

            final pastRevenues =
                filteredRevenues.where((r) {
                  if (r.isRegular) return false;
                  final rDate = DateTime(r.date.year, r.date.month, r.date.day);
                  return rDate.isBefore(startOfMonth);
                }).toList();

            final isEmpty = filteredRevenues.isEmpty && _filterData.isEmpty;

            final items = [];
            items.add('HEADER');
            items.addAll(activeRevenues);
            if (pastRevenues.isNotEmpty) {
              items.add('DIVIDER');
              items.addAll(pastRevenues);
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
                if (item == 'HEADER') {
                  return _buildHeaderContainer(
                    context,
                    filteredRevenues,
                    isEmpty,
                  );
                }
                if (item == 'DIVIDER') {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      children: [
                        const Expanded(child: FrostedDivider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Revenus passés',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Expanded(child: FrostedDivider()),
                      ],
                    ),
                  );
                }
                final revenue = item as RevenueModel;
                final account = accounts.firstWhere(
                  (a) => a.id == revenue.accountId,
                  orElse:
                      () =>
                          AccountModel.create(name: 'Compte inconnu', bank: ''),
                );
                final beneficiary =
                    revenue.beneficiaryId != null
                        ? beneficiaries
                            .where((b) => b.id == revenue.beneficiaryId)
                            .firstOrNull
                        : null;
                return RevenueCard(
                  revenue: revenue,
                  accountName: account.name,
                  beneficiaryName: beneficiary?.name,
                  onDelete: () async {
                    try {
                      await ref
                          .read(revenueProvider.notifier)
                          .deleteRevenue(revenue.id);
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
    List<RevenueModel> displayedRevenues,
    bool isEmpty,
  ) {
    final monthlyRevenues =
        ref.read(revenueProvider.notifier).getMonthlyRevenues();
    final fixedRevenues =
        ref.read(revenueProvider.notifier).getMonthlyFixedRevenues();
    final punctualRevenues =
        ref.read(revenueProvider.notifier).getMonthlyPunctualRevenues();
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 15, bottom: 5),
          child: RevenuesSummaryCard(
            transactionCount: displayedRevenues.length,
            monthlyRevenues: monthlyRevenues,
            fixedRevenues: fixedRevenues,
            punctualRevenues: punctualRevenues,
          ),
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
                          hintText: 'Rechercher un revenu...',
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
                        'Mes revenus',
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
      message: 'Aucun revenu enregistré',
      subMessage: 'Ajoutez vos revenus pour commencer à gérer vos finances',
      icon: Icons.trending_up,
      buttonText: 'Ajouter un revenu',
      onPressed: () {
        final accounts = ref.read(accountProvider).value ?? [];
        RevenueBottomSheet.show(
          context: context,
          accounts: accounts,
          onSubmit: (newRevenue) async {
            try {
              await ref.read(revenueProvider.notifier).addRevenue(newRevenue);
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
}
