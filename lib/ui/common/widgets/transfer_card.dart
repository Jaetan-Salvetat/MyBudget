import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/entities/transfer.dart';

class TransferCard extends StatelessWidget {
  final Transfer transfer;
  final int currentAccountId;
  final String otherAccountName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransferCard({
    required this.transfer,
    required this.currentAccountId,
    required this.otherAccountName,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final isOutgoing = transfer.isOutgoingFrom(currentAccountId);
    final directionColor = isOutgoing
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    final directionLabel = isOutgoing
        ? 'Vers $otherAccountName'
        : 'Depuis $otherAccountName';
    final directionIcon = isOutgoing
        ? Symbols.arrow_upward_rounded
        : Symbols.arrow_downward_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FrostedCard(
        radius: FrostedRadius.md,
        padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
        onTap: onEdit,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: directionColor,
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
                        color: directionColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        directionIcon,
                        color: directionColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transfer.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Symbols.swap_horiz_rounded,
                                size: 14,
                                color: directionColor,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  directionLabel,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: directionColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatter.format(transfer.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: directionColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            transfer.frequency.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    FrostedIconButton.standard(
                      icon: Symbols.more_vert_rounded,
                      onPressed: () => _showOptionsBottomSheet(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context) {
    showFrostedBottomSheet<void>(
      context: context,
      builder: (_) => FrostedBottomSheet(
        title: 'Actions',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FrostedListTile(
              title: 'Modifier',
              leading: const Icon(Symbols.edit_rounded),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            FrostedListTile(
              title: 'Supprimer',
              leading: Icon(
                Symbols.delete_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showFrostedDialog<void>(
      context: context,
      builder: (_) => FrostedDialog(
        title: 'Confirmer la suppression',
        body: const Text('Voulez-vous vraiment supprimer ce virement ?'),
        actions: [
          FrostedButton.text(
            label: 'Annuler',
            onPressed: () => Navigator.pop(context),
          ),
          FrostedButton.text(
            label: 'Supprimer',
            destructive: true,
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}
