import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/domain/entities/account.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final NumberFormat formatter;
  final VoidCallback onTap;

  const AccountCard({
    required this.account,
    required this.formatter,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double balance = double.tryParse(account.bank) ?? 0.0;
    final Color amountColor = balance >= 0
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      _getIconForAccountType(account.bank),
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        account.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formatter.format(balance),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  account.bank,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForAccountType(String bank) {
    switch (bank.toLowerCase()) {
      case 'courant':
      case 'société générale':
      case 'bnp':
      case 'crédit agricole':
        return Icons.account_balance;
      case 'épargne':
      case 'livret a':
      case 'pel':
        return Icons.savings;
      case 'carte de crédit':
      case 'american express':
        return Icons.credit_card;
      case 'investissement':
      case 'bourse':
        return Icons.trending_up;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
