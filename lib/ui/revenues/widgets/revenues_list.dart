import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/revenues/revenues_viewmodel.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_bottom_sheet.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_card.dart';
import 'package:mybudget/ui/expenses/widgets/financial_summary_card.dart';  

class RevenuesList extends StatelessWidget {
  const RevenuesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<RevenueViewModel, AccountViewModel>(
      builder: (context, revenueVM, accountVM, child) {
        if (revenueVM.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final revenues = revenueVM.revenues;
        final isEmpty = revenues.isEmpty;

        return Column(
          children: [
            _buildSummaryHeader(context, accountVM),
            _buildSectionHeader(context),
            if (isEmpty) _buildEmptyState(context),
            if (!isEmpty)
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    top: 16,
                    bottom: 100,
                    left: 16,
                    right: 16,
                  ),
                  itemCount: revenues.length,
                  itemBuilder: (context, index) {
                    final revenue = revenues[index];
                    final account = accountVM.accounts.firstWhere(
                      (a) => a.id == revenue.accountId,
                      orElse:
                          () => AccountModel.create(
                            name: 'Compte inconnu',
                            bank: '',
                          ),
                    );

                    return RevenueCard(
                      revenue: revenue,
                      accountName: account.name,
                      onDelete: () {
                        revenueVM.deleteRevenue(revenue.id);
                      },
                      onEdit: () {
                        RevenueBottomSheet.show(
                          context: context,
                          accounts: accountVM.accounts,
                          revenue: revenue,
                          onSubmit: (updatedRevenue) {
                            revenueVM.updateRevenue(updatedRevenue);
                          },
                          onCancel: () {},
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryHeader(BuildContext context, AccountViewModel accountVM) {
    final totalBalance = accountVM.getTotalBalance();
    final isPositive = totalBalance >= 0;
    final primaryColor =
        isPositive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error;

    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        margin: const EdgeInsets.only(top: 15, bottom: 5),
        child: FinancialSummaryCard(
          title: 'Solde total',
          titleIcon: Icons.account_balance,
          primaryColor: primaryColor,
          amount: totalBalance,
          trendIcon: isPositive ? Icons.trending_up : Icons.trending_down,
          itemCount: accountVM.getTotalTransactionsCount(),
          formatter: formatter,
          childContent: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    context: context,
                    title: 'Solde Total',
                    amount: totalBalance,
                    icon: Icons.arrow_upward,
                    color: Theme.of(context).colorScheme.primary,
                    formatter: formatter,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.08),
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
                                ).colorScheme.primary.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${accountVM.getTotalTransactionsCount()}',
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
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required BuildContext context,
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required NumberFormat formatter,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mes revenus',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun revenu enregistré',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez vos revenus pour commencer à gérer vos finances',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
