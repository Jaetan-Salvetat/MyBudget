import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/models/transaction_item.dart';
import 'package:mybudget/ui/account_details/widgets/transaction_options_bottom_sheet.dart';

class TransactionsList extends StatelessWidget {
  final List<TransactionItem> transactions;
  final NumberFormat formatter;
  final Function(TransactionItem) onDelete;

  const TransactionsList({
    required this.transactions,
    required this.formatter,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return FrostedCard(
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long,
                size: 48,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune transaction',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FrostedCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const FrostedDivider(height: 1),
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return _TransactionListItem(
            transaction: transaction,
            formatter: formatter,
            onDelete: () => onDelete(transaction),
          );
        },
      ),
    );
  }
}

class _TransactionListItem extends StatelessWidget {
  final TransactionItem transaction;
  final NumberFormat formatter;
  final VoidCallback onDelete;

  const _TransactionListItem({
    required this.transaction,
    required this.formatter,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.amount < 0;
    final color =
        isExpense
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary;

    final formattedAmount = formatter.format(transaction.amount);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(transaction.type.icon, color: color, size: 20),
      ),
      title: Text(
        transaction.label,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        DateFormat('d MMMM', 'fr_FR').format(transaction.date),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formattedAmount,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          FrostedIconButton(
            icon: Icons.more_vert_rounded,
            onPressed: () {
              TransactionOptionsBottomSheet.show(context, onDelete: onDelete);
            },
          ),
        ],
      ),
    );
  }
}
