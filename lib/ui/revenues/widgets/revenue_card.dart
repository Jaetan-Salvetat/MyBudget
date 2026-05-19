import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/common/widgets/beneficiary_avatar.dart';

class RevenueCard extends StatelessWidget {
  final RevenueModel revenue;
  final String accountName;
  final Beneficiary? beneficiary;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const RevenueCard({
    required this.revenue,
    required this.accountName,
    required this.onDelete,
    required this.onEdit,
    this.beneficiary,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    final dateLabel = switch (revenue.frequencyEnum) {
      Frequency.monthly => 'Le ${revenue.startDate.day}',
      Frequency.annual =>
        DateFormat("'Le' d MMMM", 'fr_FR').format(revenue.startDate),
      Frequency.oneTime =>
        DateFormat('d MMMM', 'fr_FR').format(revenue.startDate),
    };

    final accentColor = beneficiary != null && beneficiary!.color != 0
        ? Color(beneficiary!.color)
        : finance.income;

    final metaParts = <String>[
      dateLabel,
      accountName,
      if (beneficiary != null) beneficiary!.name,
    ];

    return FrostedCard(
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: 14,
      padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
      onClick: onEdit,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 10),
            if (beneficiary != null)
              BeneficiaryAvatar(
                name: beneficiary!.name,
                initials: beneficiary!.initials,
                avatarColor: beneficiary!.color,
                radius: 18,
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: finance.income.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.savings_rounded,
                    color: finance.income, size: 18),
              ),
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
                          revenue.name,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 20 / 15,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (revenue.frequencyEnum == Frequency.monthly) ...[
                        const SizedBox(width: 6),
                        _FreqBadge(letter: 'M', color: scheme.primary),
                      ] else if (revenue.frequencyEnum == Frequency.annual) ...[
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
              '+ ${formatter.format(revenue.amount)}',
              style: TextStyle(
                fontSize: 15,
                height: 20 / 15,
                fontWeight: FontWeight.w600,
                color: finance.income,
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
      content: const Text('Voulez-vous vraiment supprimer ce revenu ?'),
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
