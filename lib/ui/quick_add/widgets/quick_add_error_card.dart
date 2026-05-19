import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_input_bar.dart';

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

    return FrostedContainer(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      borderRadius: BorderRadius.circular(22),
      blurStrength: kQuickAddBlur,
      backgroundColor: finance.expense.withValues(alpha: 0.18),
      borderColor: finance.expense.withValues(alpha: 0.30),
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
              Icons.error_rounded,
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
          FrostedFilledButton(
            onPressed: onRetry,
            backgroundColor: finance.expense,
            foregroundColor: scheme.onError,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: const Text(
              'Réessayer',
              style: TextStyle(
                fontSize: 13,
                height: 16 / 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
