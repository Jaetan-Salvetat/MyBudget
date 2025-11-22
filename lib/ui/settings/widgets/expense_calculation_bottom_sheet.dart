import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/annual_expense_calculation_mode.dart';

class ExpenseCalculationBottomSheet extends StatelessWidget {
  final AnnualExpenseCalculationMode currentMode;
  final Function(AnnualExpenseCalculationMode) onModeSelected;

  const ExpenseCalculationBottomSheet({
    required this.currentMode,
    required this.onModeSelected,
    super.key,
  });

  static void show({
    required BuildContext context,
    required AnnualExpenseCalculationMode currentMode,
    required Function(AnnualExpenseCalculationMode) onModeSelected,
  }) {
    FrostedBottomSheet.show(
      context: context,
      title: 'Mode de calcul',
      child: ExpenseCalculationBottomSheet(
        currentMode: currentMode,
        onModeSelected: onModeSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }

  Widget _buildOption(
    BuildContext context,
    AnnualExpenseCalculationMode mode,
    String title,
    String description,
  ) {
    final isSelected = currentMode == mode;

    return FrostedListTile(
      onTap: () {
        onModeSelected(mode);
        Navigator.pop(context);
      },
      leading: FrostedRadio<AnnualExpenseCalculationMode>(
        value: mode,
        groupValue: currentMode,
        onChanged: (value) {
          if (value != null) {
            onModeSelected(value);
            Navigator.pop(context);
          }
        },
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
