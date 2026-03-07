import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/revenues/revenues_viewmodel.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/settings/beneficiary_viewmodel.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_bottom_sheet.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_card.dart';
import 'package:mybudget/ui/revenues/widgets/revenues_summary_card.dart';
import 'package:mybudget/ui/common/empty_state.dart';

class RevenuesList extends StatelessWidget {
  const RevenuesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<RevenueViewModel, AccountViewModel, BeneficiaryViewModel>(
      builder: (context, revenueVM, accountVM, beneficiaryVM, child) {
        if (revenueVM.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final revenues = revenueVM.revenues;
        final isEmpty = revenues.isEmpty;

        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);

        final activeRevenues =
            revenues.where((r) {
              if (r.isRegular) return true;
              final rDate = DateTime(r.date.year, r.date.month, r.date.day);
              return !rDate.isBefore(startOfMonth);
            }).toList();

        final pastRevenues =
            revenues.where((r) {
              if (r.isRegular) return false;
              final rDate = DateTime(r.date.year, r.date.month, r.date.day);
              return rDate.isBefore(startOfMonth);
            }).toList();

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
              return _buildHeaderContainer(context, revenueVM, isEmpty);
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
            final account = accountVM.accounts.firstWhere(
              (a) => a.id == revenue.accountId,
              orElse:
                  () => AccountModel.create(name: 'Compte inconnu', bank: ''),
            );

            final beneficiary =
                revenue.beneficiaryId != null
                    ? beneficiaryVM.getBeneficiaryById(revenue.beneficiaryId!)
                    : null;

            return RevenueCard(
              revenue: revenue,
              accountName: account.name,
              beneficiaryName: beneficiary?.name,
              onDelete: () {
                revenueVM.deleteRevenue(revenue.id);
              },
              onEdit: () {
                RevenueBottomSheet.show(
                  context: context,
                  accounts: accountVM.accounts,
                  beneficiaries: beneficiaryVM.beneficiaries,
                  revenue: revenue,
                  onSubmit: (updatedRevenue) {
                    revenueVM.updateRevenue(updatedRevenue);
                  },
                  onCreateBeneficiary:
                      (name) => beneficiaryVM.addBeneficiary(name),
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
    RevenueViewModel revenueVM,
    bool isEmpty,
  ) {
    final monthlyRevenues = revenueVM.getMonthlyRevenues();
    final fixedRevenues = revenueVM.getMonthlyFixedRevenues();
    final punctualRevenues = revenueVM.getMonthlyPunctualRevenues();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 15, bottom: 5),
          child: RevenuesSummaryCard(
            transactionCount: revenueVM.revenues.length,
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
    return EmptyState(
      message: 'Aucun revenu enregistré',
      subMessage: 'Ajoutez vos revenus pour commencer à gérer vos finances',
      icon: Icons.trending_up,
      buttonText: 'Ajouter un revenu',
      onPressed: () {
        final accountVM = Provider.of<AccountViewModel>(context, listen: false);
        final revenueVM = Provider.of<RevenueViewModel>(context, listen: false);

        final beneficiaryVM = Provider.of<BeneficiaryViewModel>(
          context,
          listen: false,
        );

        RevenueBottomSheet.show(
          context: context,
          accounts: accountVM.accounts,
          beneficiaries: beneficiaryVM.beneficiaries,
          onSubmit: (newRevenue) {
            revenueVM.addRevenue(newRevenue);
          },
          onCreateBeneficiary: (name) => beneficiaryVM.addBeneficiary(name),
          onCancel: () {},
        );
      },
    );
  }
}
