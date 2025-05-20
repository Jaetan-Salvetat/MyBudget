import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/core/controllers/revenue_controller.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/presentation/widgets/common/empty_state_view.dart';
import 'package:mybudget/presentation/widgets/common/financial_summary_card.dart';
import 'package:mybudget/presentation/widgets/common/section_header.dart';
import 'package:mybudget/presentation/widgets/revenues/revenu_card.dart';
import 'package:mybudget/presentation/widgets/revenues/revenue_bottom_sheet.dart';

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

      return Expanded(
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: revenues.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _summaruHeaderContainer(context, revenues.isEmpty);
            }

            final revenue = revenues[index - 1];

            AccountModel? account;

            try {
              account = accounts.firstWhere((a) => a.id == revenue.accountId);
            } catch (_) {
              account = null;
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
      );
    });
  }

  Widget _summaruHeaderContainer(BuildContext context, bool isEmpty) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 15, bottom: 5),
          child: Obx(() {
            final accountController = Get.find<AccountController>();
            final totalBalance = accountController.getTotalBalance();
            final formatter = NumberFormat.currency(
              locale: 'fr_FR',
              symbol: '€',
            );
            final isPositive = totalBalance >= 0;
            final primaryColor =
                isPositive
                    ? Colors.green.shade700
                    : Theme.of(context).colorScheme.error;

            return FinancialSummaryCard(
              title: 'Solde total',
              titleIcon: Icons.account_balance,
              primaryColor: primaryColor,
              amount: totalBalance,
              trendIcon: isPositive ? Icons.trending_up : Icons.trending_down,
              trendLabel: '85.5%',
              formatter: formatter,
              childContent: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700.withOpacity(0.08),
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
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Solde Total',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green.shade700.withOpacity(
                                      0.8,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formatter.format(totalBalance),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
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
                                  Icons.compare_arrows,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Transactions',
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
                            Text(
                              '${accountController.getTotalTransactionsCount()}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SectionHeader(title: 'Mes revenus'),
        if (isEmpty)
          EmptyStateView(
            title: 'Aucun revenu enregistré',
            message: 'Ajoutez vos revenus pour commencer à gérer vos finances',
            icon: Icons.add,
            buttonText: 'Ajouter un revenu',
            onButtonPressed: () => _showAddRevenueBottomSheet(context),
          ),
      ],
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
