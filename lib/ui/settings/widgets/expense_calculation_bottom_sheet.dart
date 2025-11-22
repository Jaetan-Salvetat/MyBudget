import 'package:flutter/material.dart';
import 'package:mybudget/core/enums/annual_expense_calculation_mode.dart';

class ExpenseCalculationBottomSheet extends StatelessWidget {
  final AnnualExpenseCalculationMode currentMode;
  final Function(AnnualExpenseCalculationMode) onModeSelected;

  const ExpenseCalculationBottomSheet({
    required this.currentMode,
    required this.onModeSelected,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required AnnualExpenseCalculationMode currentMode,
    required Function(AnnualExpenseCalculationMode) onModeSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => ExpenseCalculationBottomSheet(
            currentMode: currentMode,
            onModeSelected: onModeSelected,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mode de calcul',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildOption(
            context,
            AnnualExpenseCalculationMode.monthlyAmortized,
            'Amortissement mensuel',
            'Divise le montant annuel par 12 et l\'ajoute aux dépenses de chaque mois.',
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            AnnualExpenseCalculationMode.dateBasedOnly,
            'Mois spécifique uniquement',
            'Le montant total est comptabilisé uniquement le mois de la dépense.',
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    AnnualExpenseCalculationMode mode,
    String title,
    String description,
  ) {
    final isSelected = currentMode == mode;

    return InkWell(
      onTap: () {
        onModeSelected(mode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border:
              isSelected
                  ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                  : null,
        ),
        child: Row(
          children: [
            Radio<AnnualExpenseCalculationMode>(
              value: mode,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  onModeSelected(value);
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
