import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/accounts/widgets/account_bottom_sheet.dart';
import 'package:mybudget/ui/account_details/screens/account_details_screen.dart';
import 'package:mybudget/ui/common/empty_state.dart';
import 'package:mybudget/ui/common/widgets/month_selector.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/transfers/transfers_provider.dart';

class AccountList extends ConsumerWidget {
  const AccountList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(accountProvider)
        .when(
          loading:
              () => const Center(child: FrostedCircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erreur: $error')),
          data: (accounts) {
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

            final now = DateTime.now();
            return ListView.builder(
              padding: const EdgeInsets.only(
                top: 120,
                bottom: 145,
                left: 16,
                right: 16,
              ),
              itemCount: accounts.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const MonthSelector();
                }
                final account = accounts[index - 1];
                final balance = ref
                    .read(accountProvider.notifier)
                    .getAccountBalance(account.id);

                final accountExpenses = ref
                    .read(expenseProvider.notifier)
                    .getExpensesForAccount(account.id)
                    .where((e) => e.endDate == null)
                    .toList();

                final currentMonthExpenses = accountExpenses
                    .where((e) =>
                        e.frequencyEnum == Frequency.monthly ||
                        (e.frequencyEnum == Frequency.annual &&
                            e.startDate.month == now.month))
                    .fold(0.0, (double sum, e) => sum + e.amount);

                final monthlyRevenues = ref
                    .read(revenueProvider.notifier)
                    .getRevenuesForAccount(account.id)
                    .where((r) => r.endDate == null)
                    .fold(0.0, (double sum, r) => sum + r.amount);

                final transferNotifier = ref.read(transferProvider.notifier);
                final outgoingTransfers = transferNotifier.getOutgoingTotalForAccount(account.id);
                final incomingTransfers = transferNotifier.getIncomingTotalForAccount(account.id);

                return _AccountCard(
                  account: account,
                  balance: balance,
                  currentMonthExpenses: currentMonthExpenses + outgoingTransfers,
                  monthlyRevenues: monthlyRevenues + incomingTransfers,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AccountDetailsScreen(account: account),
                        settings: RouteSettings(arguments: account),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    AccountBottomSheet.show(
      context: context,
      onSubmit: (name, bank) async {
        if (name.isEmpty || bank.isEmpty) return;

        try {
          final account = AccountModel.create(name: name, bank: bank);
          await ref.read(accountProvider.notifier).addAccount(account);
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
  }
}

class _AccountCard extends StatelessWidget {
  final AccountModel account;
  final double balance;
  final double currentMonthExpenses;
  final double monthlyRevenues;
  final VoidCallback onTap;

  const _AccountCard({
    required this.account,
    required this.balance,
    required this.currentMonthExpenses,
    required this.monthlyRevenues,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final balanceColor =
        balance >= 0
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error;
    final now = DateTime.now();
    final monthLabel = DateFormat.MMMM('fr_FR').format(now);

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

          const SizedBox(height: 16),
          FrostedDivider(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),

          Text(
            'En $monthLabel',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Charges',
                  currentMonthExpenses,
                  Icons.arrow_downward,
                  Theme.of(context).colorScheme.error,
                  currencyFormat,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Revenus',
                  monthlyRevenues,
                  Icons.arrow_upward,
                  Theme.of(context).colorScheme.primary,
                  currencyFormat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    double amount,
    IconData icon,
    Color color,
    NumberFormat formatter,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color.withValues(alpha: 0.8)),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          formatter.format(amount),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
