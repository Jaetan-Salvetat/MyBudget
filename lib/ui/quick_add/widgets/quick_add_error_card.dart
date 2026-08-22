import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/theme/finance_colors.dart';

class QuickAddErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const QuickAddErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: finance.expense.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(FrostedRadius.xl),
        border: Border.all(color: finance.expense.withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: finance.expense.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Symbols.error_rounded,
                size: 20,
                color: finance.expense,
                fill: 1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Impossible de lire la saisie',
                    style: TextStyle(
                      fontSize: 14,
                      height: 18 / 14,
                      fontWeight: FontWeight.w600,
                      color: finance.expenseOnSoft,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FrostedButton.filled(
              label: 'Réessayer',
              destructive: true,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
