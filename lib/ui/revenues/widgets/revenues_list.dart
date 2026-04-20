import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
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
import 'package:mybudget/ui/common/widgets/month_selector.dart';

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
            final selectedMonth = ref.watch(selectedMonthProvider);
            final accounts = ref.watch(accountProvider).value ?? [];
            final beneficiaries = ref.watch(beneficiaryProvider).value ?? [];

            final activeRevenues = revenues
                .where((r) => r.endDate == null)
                .toList();

            List<RevenueModel> filteredRevenues = activeRevenues;

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
                    if (_filterData.frequencies.isNotEmpty &&
                        !_filterData.frequencies.contains(revenue.frequency)) {
                      return false;
                    }
                    return true;
                  }).toList();
            }

            final recurringRevenues = filteredRevenues
                .where((r) {
                  if (r.frequencyEnum == Frequency.oneTime) return false;
                  if (r.frequencyEnum == Frequency.annual) {
                    return r.startDate.month == selectedMonth.month;
                  }
                  return true;
                })
                .toList();
            final oneTimeRevenues = filteredRevenues
                .where((r) =>
                    r.frequencyEnum == Frequency.oneTime &&
                    r.startDate.year == selectedMonth.year &&
                    r.startDate.month == selectedMonth.month)
                .toList();

            final isEmpty = recurringRevenues.isEmpty &&
                oneTimeRevenues.isEmpty &&
                _filterData.isEmpty;

            final items = <_RevenueListItem>[];
            items.add(_RevenueListItem.monthSelector());
            items.add(_RevenueListItem.header(
              [...recurringRevenues, ...oneTimeRevenues],
              isEmpty,
            ));

            if (recurringRevenues.isNotEmpty) {
              items.add(_RevenueListItem.sectionTitle('Récurrents'));
              for (final revenue in recurringRevenues) {
                items.add(_RevenueListItem.revenue(revenue));
              }
            }

            if (oneTimeRevenues.isNotEmpty) {
              final monthLabel = DateFormat('MMMM yyyy', 'fr_FR').format(selectedMonth);
              final capitalized = monthLabel.replaceFirst(monthLabel[0], monthLabel[0].toUpperCase());
              items.add(_RevenueListItem.sectionTitle('Ponctuels — $capitalized'));
              for (final revenue in oneTimeRevenues) {
                items.add(_RevenueListItem.revenue(revenue));
              }
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

                if (item.type == _RevenueItemType.monthSelector) {
                  return const MonthSelector();
                }

                if (item.type == _RevenueItemType.header) {
                  return _buildHeaderContainer(
                    context,
                    [...recurringRevenues, ...oneTimeRevenues],
                    isEmpty,
                  );
                }

                if (item.type == _RevenueItemType.sectionTitle) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      item.title!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                final revenue = item.revenue!;
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
                  beneficiary: beneficiary,
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
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 5),
          child: RevenuesSummaryCard(
            transactionCount: displayedRevenues.length,
            monthlyRevenues: monthlyRevenues,
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
          closedRevenues: ref.read(revenueProvider.notifier).getClosedRevenues(),
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

enum _RevenueItemType { monthSelector, header, sectionTitle, revenue }

class _RevenueListItem {
  final _RevenueItemType type;
  final List<RevenueModel>? revenues;
  final bool? isEmpty;
  final String? title;
  final RevenueModel? revenue;

  _RevenueListItem._({
    required this.type,
    this.revenues,
    this.isEmpty,
    this.title,
    this.revenue,
  });

  factory _RevenueListItem.header(List<RevenueModel> revenues, bool isEmpty) =>
      _RevenueListItem._(type: _RevenueItemType.header, revenues: revenues, isEmpty: isEmpty);

  factory _RevenueListItem.sectionTitle(String title) =>
      _RevenueListItem._(type: _RevenueItemType.sectionTitle, title: title);

  factory _RevenueListItem.revenue(RevenueModel revenue) =>
      _RevenueListItem._(type: _RevenueItemType.revenue, revenue: revenue);

  factory _RevenueListItem.monthSelector() =>
      _RevenueListItem._(type: _RevenueItemType.monthSelector);
}
