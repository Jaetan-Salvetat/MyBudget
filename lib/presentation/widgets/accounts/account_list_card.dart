import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/data/models/account_model.dart';

class AccountListCard extends StatelessWidget {
  final AccountModel account;
  final double balance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const AccountListCard({
    required this.account,
    required this.balance,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final colorScheme = Theme.of(context).colorScheme;
    final bool isPositive = balance >= 0;
    final Color balanceColor = isPositive ? Colors.green.shade700 : colorScheme.error;
    
    return Card(
      elevation: 3,
      shadowColor: colorScheme.shadow.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap ?? onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      _getIconForBank(account.bank),
                      color: colorScheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          account.bank,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatter.format(balance),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: balanceColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 14,
                            color: balanceColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPositive ? 'Positif' : 'Négatif',
                            style: TextStyle(
                              fontSize: 12,
                              color: balanceColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modifier'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDeleteConfirmationDialog(context);
                    },
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Supprimer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error.withOpacity(0.1),
                      foregroundColor: colorScheme.error,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le compte ${account.name} ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              onDelete();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
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

  IconData _getIconForBank(String bank) {
    switch (bank.toLowerCase()) {
      case 'société générale':
        return Icons.account_balance;
      case 'bnp paribas':
        return Icons.account_balance;
      case 'crédit agricole':
        return Icons.account_balance;
      case 'boursorama':
        return Icons.account_balance_wallet;
      case 'livret a':
      case 'pel':
      case 'livret':
        return Icons.savings;
      case 'carte de crédit':
      case 'amex':
      case 'american express':
        return Icons.credit_card;
      case 'revolut':
      case 'n26':
        return Icons.phone_android;
      case 'paypal':
        return Icons.payment;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
