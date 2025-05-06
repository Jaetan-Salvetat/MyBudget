import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/domain/entities/account.dart';
import 'package:get/get.dart';

class AccountsOverviewCard extends StatelessWidget {
  final List<Account> accounts;
  final NumberFormat formatter;

  const AccountsOverviewCard({
    required this.accounts,
    required this.formatter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Dans un cas réel, vous utiliseriez les données de vos modèles Account
    const totalBalance = 0.0; // Simulation

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Mes comptes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  formatter.format(totalBalance),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        totalBalance >= 0
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return _buildAccountCard(context, account);
              },
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, Account account) {
    const double balance =
        0.0; // Simulation - dans un cas réel, utilisez les vraies données
    final accountType =
        account
            .bank; // Utilisation du champ 'bank' comme approximation de 'type'

    final Color cardColor =
        balance >= 0
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error;

    return GestureDetector(
      onTap: () => Get.toNamed('/account-details', arguments: account),
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: cardColor.withOpacity(0.1),
          border: Border.all(color: cardColor.withOpacity(0.3), width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getAccountIcon(accountType), size: 20, color: cardColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    account.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              formatter.format(balance),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cardColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              accountType,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAccountIcon(String type) {
    switch (type.toLowerCase()) {
      case 'checking':
      case 'courant':
        return Icons.account_balance;
      case 'savings':
      case 'épargne':
        return Icons.savings;
      case 'credit card':
      case 'carte de crédit':
        return Icons.credit_card;
      case 'investment':
      case 'investissement':
        return Icons.trending_up;
      case 'cash':
      case 'espèces':
        return Icons.payments;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
