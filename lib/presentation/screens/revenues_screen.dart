import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../widgets/common/app_scaffold.dart';
import '../../core/controllers/revenue_controller.dart';
import '../../core/controllers/account_controller.dart';
import '../../data/models/revenue_model.dart';
import '../../data/models/account_model.dart';
import '../widgets/revenues/revenue_bottom_sheet.dart';

class RevenuesScreen extends StatelessWidget {
  final bool isNested;
  final String fabTag;

  const RevenuesScreen({
    this.isNested = false,
    this.fabTag = 'revenues_fab',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isNested) {
      return Stack(
        children: [
          RevenuesList(isNested: true),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: fabTag,
              onPressed: () => _showAddRevenueBottomSheet(context),
              tooltip: 'Ajouter un revenu',
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }

    return AppScaffold(
      title: 'Revenus',
      useNestedAppBar: false,
      floatingActionButton: FloatingActionButton(
        heroTag: fabTag,
        onPressed: () => _showAddRevenueBottomSheet(context),
        tooltip: 'Ajouter un revenu',
        child: const Icon(Icons.add),
      ),
      child: const RevenuesList(),
    );
  }

  void _showAddRevenueBottomSheet(BuildContext context) {
    final accountController = Get.find<AccountController>();
    final revenueController = Get.find<RevenueController>();

    RevenueBottomSheet.show(
      context: context,
      accounts: accountController.accounts,
      onSubmit: (revenue) {
        revenueController.addRevenue(revenue);
        Navigator.of(context).pop();
      },
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}

class RevenuesList extends StatelessWidget {
  final bool isNested;

  const RevenuesList({this.isNested = false, super.key});

  @override
  Widget build(BuildContext context) {
    final revenueController = Get.find<RevenueController>();
    final accountController = Get.find<AccountController>();

    return Obx(() {
      final revenues = revenueController.revenues;
      final accounts = accountController.accounts;

      if (revenues.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Aucun revenu enregistré',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  RevenueBottomSheet.show(
                    context: context,
                    accounts: accountController.accounts,
                    onSubmit: (revenue) {
                      revenueController.addRevenue(revenue);
                      Navigator.of(context).pop();
                    },
                    onCancel: () => Navigator.of(context).pop(),
                  );
                },
                child: const Text('Ajouter un revenu'),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 130, 16, 5),
            child: Card(
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.05),
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.account_balance_wallet,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Revenus',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${revenues.length}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Obx(() {
                          final totalRevenues =
                              revenueController.getTotalRevenues();
                          final formatter = NumberFormat.currency(
                            locale: 'fr_FR',
                            symbol: '€',
                          );

                          return Text(
                            formatter.format(totalRevenues),
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              letterSpacing: -0.5,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_upward,
                                      size: 16,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Mensuel',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Obx(() {
                                  final monthlyRevenues =
                                      revenueController.getTotalRevenues();
                                  final formatter = NumberFormat.currency(
                                    locale: 'fr_FR',
                                    symbol: '€',
                                  );

                                  return Text(
                                    formatter.format(monthlyRevenues),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.date_range,
                                      size: 16,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Annuel',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Obx(() {
                                  final annualRevenues =
                                      revenueController.getTotalRevenues() * 12;
                                  final formatter = NumberFormat.currency(
                                    locale: 'fr_FR',
                                    symbol: '€',
                                  );

                                  return Text(
                                    formatter.format(annualRevenues),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: revenues.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final revenue = revenues[index];

                AccountModel? account;
                if (accounts.isNotEmpty) {
                  try {
                    account = accounts.firstWhere(
                      (a) => a.id == revenue.accountId,
                    );
                  } catch (_) {
                    account = accounts.first;
                  }
                }
                final accountName = account?.name ?? 'Compte inconnu';

                return RevenueCard(
                  revenue: revenue,
                  accountName: accountName,
                  onDelete: () {
                    revenueController.deleteRevenue(revenue.id);
                  },
                  onEdit: () {
                    RevenueBottomSheet.show(
                      context: context,
                      accounts: accounts,
                      revenue: revenue,
                      onSubmit: (updatedRevenue) {
                        revenueController.updateRevenue(updatedRevenue);
                        Navigator.of(context).pop();
                      },
                      onCancel: () => Navigator.of(context).pop(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

class RevenueCard extends StatelessWidget {
  final RevenueModel revenue;
  final String accountName;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const RevenueCard({
    required this.revenue,
    required this.accountName,
    required this.onDelete,
    required this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.payments,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        revenue.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        accountName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${revenue.amount.toStringAsFixed(2)} €',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (revenue.isRegular)
                  Chip(
                    label: const Text('Régulier'),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                Chip(
                  label: Text(
                    '${revenue.date.day}/${revenue.date.month}/${revenue.date.year}',
                  ),
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Confirmer la suppression'),
                            content: Text(
                              'Voulez-vous vraiment supprimer ${revenue.name} ?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                                onPressed: () {
                                  onDelete();
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Supprimer'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
                IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
