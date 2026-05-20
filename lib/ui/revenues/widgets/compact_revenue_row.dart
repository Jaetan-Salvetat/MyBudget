import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/common/widgets/beneficiary_avatar.dart';

class CompactRevenueRow extends StatelessWidget {
  final RevenueModel revenue;
  final String accountName;
  final Beneficiary? beneficiary;
  final bool showDivider;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CompactRevenueRow({
    required this.revenue,
    required this.accountName,
    required this.onEdit,
    required this.onDelete,
    this.beneficiary,
    this.showDivider = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    final isRecurrent = revenue.frequencyEnum != Frequency.oneTime;
    final letter = switch (revenue.frequencyEnum) {
      Frequency.monthly => 'M',
      Frequency.annual => 'A',
      Frequency.oneTime => null,
    };
    final badgeColor = revenue.frequencyEnum == Frequency.monthly
        ? scheme.primary
        : scheme.secondary;

    final dateLabel = switch (revenue.frequencyEnum) {
      Frequency.monthly => 'Le ${revenue.startDate.day}',
      Frequency.annual =>
        DateFormat("'Le' d MMMM", 'fr_FR').format(revenue.startDate),
      Frequency.oneTime =>
        DateFormat('d MMMM', 'fr_FR').format(revenue.startDate),
    };

    final metaParts = <String>[
      dateLabel,
      accountName,
      if (beneficiary != null) beneficiary!.name,
    ];

    return InkWell(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
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
            _Leading(
              beneficiary: beneficiary,
              fallbackColor: finance.income,
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
                    revenue.name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 19 / 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    metaParts.join(' · '),
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 15 / 11.5,
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
              '+ ${formatter.format(revenue.amount).replaceAll('−', '').replaceAll('-', '').trim()}',
              style: TextStyle(
                fontSize: 14.5,
                height: 19 / 14.5,
                fontWeight: FontWeight.w600,
                color: finance.income,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 18,
                icon: const Icon(Icons.more_vert),
                color: scheme.onSurfaceVariant,
                onPressed: () => _showOptionsBottomSheet(context),
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

class _Leading extends StatelessWidget {
  final Beneficiary? beneficiary;
  final Color fallbackColor;
  final Color? ringColor;
  final String? badgeLetter;
  final Color badgeColor;

  const _Leading({
    required this.fallbackColor,
    required this.badgeColor,
    this.beneficiary,
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
              shape: BoxShape.circle,
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
            child: beneficiary != null
                ? BeneficiaryAvatar(
                    name: beneficiary!.name,
                    initials: beneficiary!.initials,
                    avatarColor: beneficiary!.color,
                    radius: 16,
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: fallbackColor.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.savings_rounded,
                      color: fallbackColor,
                      size: 17,
                    ),
                  ),
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
