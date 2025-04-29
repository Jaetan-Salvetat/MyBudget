import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/domain/entities/account.dart';
import 'package:mybudget/presentation/providers/account_provider.dart';
import 'package:mybudget/presentation/providers/expense_provider.dart';
import 'package:mybudget/presentation/providers/revenue_provider.dart';
import 'package:mybudget/presentation/widgets/accounts/account_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/accounts/account_list_card.dart';
import 'package:mybudget/presentation/widgets/accounts/empty_accounts_state.dart';
import 'package:mybudget/presentation/widgets/common/section_header.dart';
import 'package:mybudget/presentation/widgets/common/app_scaffold.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Mes Comptes',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(context, ref),
        child: const Icon(Icons.add),
        elevation: 4,
      ),
      child: Column(
        children: [
          const SizedBox(height: 130),
          const Expanded(child: AccountsList()),
        ],
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    AccountBottomSheet.show(
      context: context,
      onSubmit: (name, bank) {
        if (name.isEmpty || bank.isEmpty) return;

        final notifier = ref.read(accountNotifierProvider.notifier);

        final id = DateTime.now().millisecondsSinceEpoch.toString();
        final account = AccountModel(id: id, name: name, bank: bank);

        notifier.addAccount(account);
        Navigator.of(context).pop();
      },
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}

class AccountsList extends ConsumerWidget {
  const AccountsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountNotifierProvider);
    final expenses = ref.watch(expenseNotifierProvider);
    final revenues = ref.watch(revenueNotifierProvider);

    if (accounts.isEmpty) {
      return EmptyAccountsState(
        onAddPressed: () => _showAddAccountDialog(context, ref),
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
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];

              final accountExpenses = expenses
                  .where((expense) => expense.accountId == account.id)
                  .fold(0.0, (sum, expense) => sum + expense.amount);

              final accountRevenues = revenues
                  .where((revenue) => revenue.accountId == account.id)
                  .fold(0.0, (sum, revenue) => sum + revenue.amount);

              final balance = accountRevenues - accountExpenses;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AccountListCard(
                  account: account,
                  balance: balance,
                  onDelete:
                      () => _deleteAccount(
                        context,
                        ref,
                        account,
                        expenses,
                        revenues,
                      ),
                  onEdit: () => _editAccount(context, ref, account),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    AccountBottomSheet.show(
      context: context,
      onSubmit: (name, bank) {
        if (name.isEmpty || bank.isEmpty) return;

        final notifier = ref.read(accountNotifierProvider.notifier);

        final id = DateTime.now().millisecondsSinceEpoch.toString();
        final account = AccountModel(id: id, name: name, bank: bank);

        notifier.addAccount(account);
        Navigator.of(context).pop();
      },
      onCancel: () => Navigator.of(context).pop(),
    );
  }

  void _editAccount(BuildContext context, WidgetRef ref, Account account) {
    AccountBottomSheet.show(
      context: context,
      account: account,
      onSubmit: (name, bank) {
        if (name.isEmpty || bank.isEmpty) return;

        final updatedAccount = AccountModel(
          id: account.id,
          name: name,
          bank: bank,
        );

        ref
            .read(accountNotifierProvider.notifier)
            .updateAccount(updatedAccount);

        Navigator.of(context).pop();
      },
      onCancel: () => Navigator.of(context).pop(),
    );
  }

  void _deleteAccount(
    BuildContext context,
    WidgetRef ref,
    Account account,
    List<dynamic> expenses,
    List<dynamic> revenues,
  ) {
    final canDelete =
        !expenses.any((e) => e.accountId == account.id) &&
        !revenues.any((r) => r.accountId == account.id);

    if (canDelete) {
      ref.read(accountNotifierProvider.notifier).deleteAccount(account.id);
    } else {
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
                  child: const Text('OK'),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
      );
    }
  }
}

class SummaryCards extends StatelessWidget {
  final List<Account> accounts;
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

    final totalExpenses = expenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
    final totalRevenues = revenues.fold(
      0.0,
      (sum, revenue) => sum + revenue.amount,
    );
    final totalBalance = totalRevenues - totalExpenses;

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
              expenses.length + revenues.length,
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
