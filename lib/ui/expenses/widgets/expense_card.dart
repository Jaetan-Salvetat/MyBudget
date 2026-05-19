import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final String accountName;
  final Beneficiary? beneficiary;
  final CategoryModel? category;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool showDivider;

  const ExpenseCard({
    required this.expense,
    required this.accountName,
    required this.onDelete,
    required this.onEdit,
    this.beneficiary,
    this.category,
    this.showDivider = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final categoryColor = category != null
        ? Color(category!.color)
        : scheme.primary;

    final dateLabel = switch (expense.frequencyEnum) {
      Frequency.monthly => 'Le ${expense.startDate.day}',
      Frequency.annual =>
        DateFormat("'Le' d MMMM", 'fr_FR').format(expense.startDate),
      Frequency.oneTime =>
        DateFormat('d MMMM', 'fr_FR').format(expense.startDate),
    };

    final metaParts = <String>[
      dateLabel,
      if (category != null) category!.name,
      if (beneficiary != null) beneficiary!.name,
    ];

    return InkWell(
      onTap: onEdit,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    width: 0.5,
                    color: scheme.onSurface.withValues(alpha: 0.07),
                  ),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _CategoryDot(color: categoryColor, icon: category?.getIconData()),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          expense.name,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 20 / 15,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (expense.frequencyEnum == Frequency.monthly) ...[
                        const SizedBox(width: 6),
                        _FreqBadge(letter: 'M', color: scheme.primary),
                      ] else if (expense.frequencyEnum == Frequency.annual) ...[
                        const SizedBox(width: 6),
                        _FreqBadge(letter: 'A', color: scheme.secondary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metaParts.join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '− ${formatter.format(expense.amount).replaceAll('−', '').replaceAll('-', '').trim()}',
              style: TextStyle(
                fontSize: 15,
                height: 20 / 15,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            FrostedIconButton(
              icon: Icons.more_vert,
              onPressed: () => _showOptionsBottomSheet(context),
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

class _CategoryDot extends StatelessWidget {
  final Color color;
  final IconData? icon;

  const _CategoryDot({required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon ?? Icons.category, color: color, size: 18),
    );
  }
}

class _FreqBadge extends StatelessWidget {
  final String letter;
  final Color color;

  const _FreqBadge({required this.letter, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 10,
          height: 13 / 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
