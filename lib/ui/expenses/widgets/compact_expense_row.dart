import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';

class CompactExpenseRow extends StatelessWidget {
  final ExpenseModel expense;
  final CategoryModel? category;
  final Beneficiary? beneficiary;
  final bool showDivider;
  final bool showDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CompactExpenseRow({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
    this.category,
    this.beneficiary,
    this.showDivider = true,
    this.showDate = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final isRecurrent = expense.frequencyEnum != Frequency.oneTime;
    final letter = switch (expense.frequencyEnum) {
      Frequency.monthly => 'M',
      Frequency.annual => 'A',
      Frequency.oneTime => null,
    };
    final badgeColor = expense.frequencyEnum == Frequency.monthly
        ? scheme.primary
        : scheme.secondary;
    final categoryColor =
        category != null ? Color(category!.color) : scheme.primary;

    final metaParts = <String>[
      if (showDate) _dateLabel(),
      if (category != null) category!.name,
      if (beneficiary != null) beneficiary!.name,
    ];

    return InkWell(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    width: 0.5,
                    color: scheme.onSurface.withValues(alpha: 0.06),
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            _CategoryDot(
              color: categoryColor,
              icon: category?.getIconData() ?? Symbols.category_rounded,
              ringColor: isRecurrent ? badgeColor : null,
              badgeLetter: letter,
              badgeColor: badgeColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    expense.name,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 20 / 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (metaParts.isNotEmpty) ...[
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
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 18,
                icon: const Icon(Symbols.more_vert_rounded),
                color: scheme.onSurfaceVariant,
                onPressed: () => _showOptionsBottomSheet(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel() {
    return switch (expense.frequencyEnum) {
      Frequency.monthly => 'Le ${expense.startDate.day}',
      Frequency.annual =>
        DateFormat("'Le' d MMMM", 'fr_FR').format(expense.startDate),
      Frequency.oneTime =>
        DateFormat('d MMMM', 'fr_FR').format(expense.startDate),
    };
  }

  void _showOptionsBottomSheet(BuildContext context) {
    FrostedBottomSheet.show(
      context: context,
      title: 'Actions',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FrostedListTile(
            leading: const Icon(Symbols.edit_rounded),
            title: const Text('Modifier'),
            onTap: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
          FrostedListTile(
            leading: Icon(
              Symbols.delete_rounded,
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
  final IconData icon;
  final Color? ringColor;
  final String? badgeLetter;
  final Color badgeColor;

  const _CategoryDot({
    required this.color,
    required this.icon,
    required this.badgeColor,
    this.ringColor,
    this.badgeLetter,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: ringColor != null
                  ? [
                      BoxShadow(
                        color: scheme.surface,
                        spreadRadius: 1.5,
                      ),
                      BoxShadow(
                        color: ringColor!,
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          if (badgeLetter != null)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeLetter!,
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
