import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/category_model.dart';


class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final String accountName;
  final Beneficiary? beneficiary;
  final CategoryModel? category;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ExpenseCard({
    required this.expense,
    required this.accountName,
    required this.onDelete,
    required this.onEdit,
    this.beneficiary,
    this.category,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    String dateStr;
    if (expense.frequency == 'Mensuel') {
      dateStr = 'le ${expense.date.day}';
    } else if (expense.frequency == 'Annuel') {
      dateStr = 'le ${DateFormat('d MMMM', 'fr_FR').format(expense.date)}';
    } else {
      dateStr = DateFormat('dd/MM/yyyy').format(expense.date);
    }

    return FrostedCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 12,
      padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
      onClick: onEdit,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: category != null
                    ? Color(category!.color)
                    : Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: category != null
                    ? Color(category!.color).withValues(alpha: 0.25)
                    : Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category?.getIconData() ?? Icons.arrow_downward,
                color: category != null
                    ? Color(category!.color)
                    : Theme.of(context).colorScheme.error,
                size: 20,
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (category != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    category!.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Color(category!.color),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      accountName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (beneficiary != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        beneficiary!.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatter.format(expense.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 4),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  expense.frequency,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          FrostedIconButton(
            icon: Icons.more_vert,
            onPressed: () => _showOptionsBottomSheet(context),
          ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context) {
    FrostedBottomSheet.show(
      context: context,
      title: 'Actions',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FrostedListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Modifier'),
            onTap: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
          FrostedListTile(
            leading: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Supprimer',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    FrostedDialog.show(
      context: context,
      title: const Text('Confirmer la suppression'),
      content: const Text('Voulez-vous vraiment supprimer cette dépense ?'),
      actions: [
        FrostedTextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FrostedTextButton(
          onPressed: () {
            Navigator.pop(context);
            onDelete();
          },
          child: Text(
            'Supprimer',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}
