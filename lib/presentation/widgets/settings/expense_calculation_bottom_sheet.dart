import 'package:flutter/material.dart';
import 'package:mybudget/core/controllers/settings_controller.dart';
import 'package:mybudget/presentation/widgets/common/modal_bottom_sheet.dart';

class ExpenseCalculationBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required AnnualExpenseCalculationMode currentMode,
    required Function(AnnualExpenseCalculationMode) onModeSelected,
  }) {
    return AppModalBottomSheet.show(
      context: context,
      title: 'Calcul des dépenses annuelles',
      content: _ExpenseCalculationContent(
        currentMode: currentMode,
        onModeSelected: onModeSelected,
      ),
      actions: const [],
    );
  }
}

class _ExpenseCalculationContent extends StatelessWidget {
  final AnnualExpenseCalculationMode currentMode;
  final Function(AnnualExpenseCalculationMode) onModeSelected;

  const _ExpenseCalculationContent({
    required this.currentMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOptionItem(
          context,
          title: 'Amortissement mensuel',
          subtitle: 'Répartir les dépenses annuelles sur 12 mois',
          icon: Icons.calendar_view_month,
          isSelected: currentMode == AnnualExpenseCalculationMode.monthlyAmortized,
          onTap: () {
            onModeSelected(AnnualExpenseCalculationMode.monthlyAmortized);
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(height: 12),
        _buildOptionItem(
          context,
          title: 'Mois spécifique uniquement',
          subtitle: 'Afficher les dépenses annuelles uniquement dans leur mois de paiement',
          icon: Icons.event,
          isSelected: currentMode == AnnualExpenseCalculationMode.dateBasedOnly,
          onTap: () {
            onModeSelected(AnnualExpenseCalculationMode.dateBasedOnly);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
