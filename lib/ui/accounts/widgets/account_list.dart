import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/accounts/widgets/account_bottom_sheet.dart';
import 'package:mybudget/ui/account_details/screens/account_details_screen.dart';
import 'package:mybudget/ui/common/empty_state.dart';

class AccountList extends ConsumerWidget {
  const AccountList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountProvider);
    final isLoading = accountState.isLoading;
    final accounts = accountState.value ?? [];

    if (isLoading) {
      return const Center(child: FrostedCircularProgressIndicator());
    }

    if (accounts.isEmpty) {
      return Center(
        child: EmptyState(
          message: 'Aucun compte',
          subMessage: 'Ajoutez un compte pour commencer',
          icon: Icons.account_balance_wallet_outlined,
          buttonText: 'Ajouter un compte',
          onPressed: () => _showAddAccountDialog(context, ref),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        top: 120,
        bottom: 145,
        left: 16,
        right: 16,
      ),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        final balance = ref.read(accountProvider.notifier).getAccountBalance(account.id);

        return AccountCard(
          account: account,
          balance: balance,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AccountDetailsScreen(account: account),
                settings: RouteSettings(arguments: account),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    AccountBottomSheet.show(
      context: context,
      onSubmit: (name, bank) {
        if (name.isEmpty || bank.isEmpty) return;

        final account = AccountModel.create(name: name, bank: bank);
        ref.read(accountProvider.notifier).addAccount(account);
      },
      onCancel: () {},
    );
  }
}

class AccountCard extends StatelessWidget {
  final AccountModel account;
  final double balance;
  final VoidCallback onTap;

  const AccountCard({
    required this.account,
    required this.balance,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final balanceColor =
        balance >= 0
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error;

    return FrostedCard(
      margin: const EdgeInsets.only(bottom: 16),
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      onClick: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                account.bank.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Icon(
                Icons.contactless,
                size: 20,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            account.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 32),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              currencyFormat.format(balance),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: balanceColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
