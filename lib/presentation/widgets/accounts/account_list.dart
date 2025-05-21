import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/core/controllers/expense_controller.dart';
import 'package:mybudget/core/controllers/revenue_controller.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/presentation/screens/account/account_details_screen.dart';
import 'package:mybudget/presentation/widgets/accounts/account_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/accounts/account_list_card.dart';
import 'package:mybudget/presentation/widgets/common/empty_state_view.dart';
import 'package:mybudget/presentation/widgets/common/section_header.dart';
import 'package:mybudget/presentation/widgets/common/financial_summary_card.dart';

class AccountsList extends StatelessWidget {
  const AccountsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final accountController = Get.find<AccountController>();
      final accounts = accountController.accounts;

      return Expanded(
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            top: 16,
            bottom: 100,
            left: 16,
            right: 16,
          ),
          itemCount: accounts.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _summaruHeaderContainer(context, accounts.isEmpty);
            }

            final account = accounts[index - 1];
            final balance = accountController.getAccountBalance(account.id);

            return AccountListCard(
              account: account,
              balance: balance,
              onTap: () => _openAccountDetails(context, account),
              onEdit: () => _editAccount(context, account),
              onDelete: () => _deleteAccount(context, account),
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
        const SectionHeader(title: 'Mes comptes bancaires'),
        if (isEmpty)
          EmptyStateView(
            title: 'Aucun compte enregistré',
            message:
                'Ajoutez vos comptes bancaires pour commencer à gérer vos finances',
            icon: Icons.add,
            buttonText: 'Ajouter un compte',
            onButtonPressed: () => _showAddAccountDialog(context),
          ),
      ],
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    final accountController = Get.find<AccountController>();

    AccountBottomSheet.show(
      context: context,
      onSubmit: (name, bank) {
        if (name.isEmpty || bank.isEmpty) return;

        final account = AccountModel.create(name: name, bank: bank);

        accountController.addAccount(account);
      },
      onCancel: () {},
    );
  }

  void _editAccount(BuildContext context, AccountModel account) {
    final accountController = Get.find<AccountController>();

    AccountBottomSheet.show(
      context: context,
      account: account,
      onSubmit: (name, bank) {
        if (name.isEmpty || bank.isEmpty) return;

        final updatedAccount = account.copyWith(name: name, bank: bank);

        accountController.updateAccount(updatedAccount);
      },
      onCancel: () {},
    );
  }

  void _openAccountDetails(BuildContext context, AccountModel account) {
    Get.to(() => AccountDetailsScreen(), arguments: account);
  }

  void _deleteAccount(BuildContext context, AccountModel account) {
    final accountController = Get.find<AccountController>();
    final expenseController = Get.find<ExpenseController>();
    final revenueController = Get.find<RevenueController>();

    final accountExpenses =
        expenseController.expenses
            .where((expense) => expense.accountId == account.id)
            .toList();
    final accountRevenues =
        revenueController.revenues
            .where((revenue) => revenue.accountId == account.id)
            .toList();

    if (accountExpenses.isNotEmpty || accountRevenues.isNotEmpty) {
      _showCannotDeleteDialog(context);
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer le compte "${account.name}" ?',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  accountController.deleteAccount(account.id);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Le compte ${account.name} a été supprimé'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }

  void _showCannotDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Impossible de supprimer'),
            content: const Text(
              'Ce compte contient des transactions. Supprimez d\'abord toutes les transactions liées à ce compte.',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
