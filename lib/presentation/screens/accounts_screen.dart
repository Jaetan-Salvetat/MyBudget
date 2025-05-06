import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/core/controllers/expense_controller.dart';
import 'package:mybudget/core/controllers/revenue_controller.dart';
import 'package:mybudget/presentation/widgets/accounts/account_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/accounts/account_list_card.dart';
import 'package:mybudget/presentation/widgets/accounts/empty_accounts_state.dart';
import 'package:mybudget/presentation/widgets/common/section_header.dart';
import 'package:mybudget/presentation/widgets/common/app_scaffold.dart';

class AccountsScreen extends StatelessWidget {
  final bool isNested;
  final String fabTag;
  
  const AccountsScreen({
    this.isNested = false,
    this.fabTag = 'accounts_fab',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [const SizedBox(height: 100), Expanded(child: AccountsList())],
    );
    
    if (isNested) {
      return Stack(
        children: [
          content,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: fabTag,
              onPressed: () => _showAddAccountDialog(context),
              elevation: 4,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }
    
    return AppScaffold(
      title: 'Mes Comptes',
      floatingActionButton: FloatingActionButton(
        heroTag: fabTag,
        onPressed: () => _showAddAccountDialog(context),
        elevation: 4,
        child: const Icon(Icons.add),
      ),
      child: content,
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
}

class AccountsList extends StatelessWidget {
  const AccountsList({super.key});

  @override
  Widget build(BuildContext context) {
    final accountController = Get.find<AccountController>();
    final expenseController = Get.find<ExpenseController>();
    final revenueController = Get.find<RevenueController>();

    return Obx(() {
      final accounts = accountController.accounts;
      final expenses = expenseController.expenses;
      final revenues = revenueController.revenues;

      if (accounts.isEmpty) {
        return EmptyAccountsState(
          onAddPressed: () => _showAddAccountDialog(context),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vue d\'ensemble',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Chip(
                  label: Text(
                    '${accounts.length} comptes',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ],
            ),
          ),

          SummaryCards(
            accounts: accounts,
            expenses: expenses,
            revenues: revenues,
          ),

          SectionHeader(
            title: 'Mes comptes bancaires',
            actionText: 'Trier',
            onActionPressed: () {},
          ),

          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];

                final balance = accountController.getAccountBalance(account.id);

                return AccountListCard(
                  account: account,
                  balance: balance,
                  onEdit: () => _editAccount(context, account),
                  onDelete: () => _deleteAccount(context, account),
                );
              },
            ),
          ),
        ],
      );
    });
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

class SummaryCards extends StatelessWidget {
  final List<AccountModel> accounts;
  final List<dynamic> expenses;
  final List<dynamic> revenues;

  const SummaryCards({
    required this.accounts,
    required this.expenses,
    required this.revenues,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final accountController = Get.find<AccountController>();

    final totalBalance = accountController.getTotalBalance();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              context,
              'Solde Total',
              totalBalance,
              formatter,
              totalBalance >= 0
                  ? Colors.green.shade700
                  : Theme.of(context).colorScheme.error,
              totalBalance >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              context,
              'Transactions',
              accountController.getTotalTransactionsCount(),
              null,
              Theme.of(context).colorScheme.primary,
              Icons.compare_arrows,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    dynamic value,
    NumberFormat? formatter,
    Color color,
    IconData icon,
  ) {
    final formattedValue =
        formatter != null ? formatter.format(value) : value.toString();

    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    formattedValue,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
