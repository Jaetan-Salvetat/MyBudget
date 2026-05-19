import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecurringSummaryCard extends StatelessWidget {
  final int count;
  final double total;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget? expandedContent;

  const RecurringSummaryCard({
    required this.count,
    required this.total,
    required this.expanded,
    required this.onToggle,
    this.expandedContent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 0.5,
          color: scheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.event_repeat,
                      color: scheme.onPrimary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Récurrentes du mois',
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 18 / 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$count dépense${count > 1 ? 's' : ''} réglée${count > 1 ? 's' : ''} automatiquement',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 15 / 11.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatter.format(total),
                    style: TextStyle(
                      fontSize: 14,
                      height: 18 / 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (expanded && expandedContent != null)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    width: 0.5,
                    color: scheme.primary.withValues(alpha: 0.14),
                  ),
                ),
              ),
              child: expandedContent,
            ),
        ],
      ),
    );
  }
}
