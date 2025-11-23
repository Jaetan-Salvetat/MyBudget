import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mybudget/core/enums/annual_expense_calculation_mode.dart';
import 'package:mybudget/ui/settings/settings_viewmodel.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';
import 'package:mybudget/ui/settings/widgets/expense_calculation_bottom_sheet.dart';

class FinancialCalculationsSection extends StatelessWidget {
  const FinancialCalculationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsVM = Provider.of<SettingsViewModel>(context);

    return SettingsSection(
      title: 'Calculs financiers',
      children: [
        SettingsTile(
          title: 'Calcul des dépenses annuelles',
          subtitle: _getAnnualExpenseCalculationModeName(
            settingsVM.annualExpenseCalculationMode,
          ),
          leading: const Icon(Icons.calculate),
          onTap: () {
            _showExpenseCalculationModeDialog(
              context,
              settingsVM.annualExpenseCalculationMode,
            );
          },
        ),
      ],
    );
  }

  String _getAnnualExpenseCalculationModeName(
    AnnualExpenseCalculationMode mode,
  ) {
    switch (mode) {
      case AnnualExpenseCalculationMode.monthlyAmortized:
        return 'Amortissement mensuel';
      case AnnualExpenseCalculationMode.dateBasedOnly:
        return 'Mois spécifique uniquement';
    }
  }

  Future<void> _showExpenseCalculationModeDialog(
    BuildContext context,
    AnnualExpenseCalculationMode currentMode,
  ) async {
    return ExpenseCalculationBottomSheet.show(
      context: context,
      currentMode: currentMode,
      onModeSelected: (AnnualExpenseCalculationMode mode) {
        final settingsVM = Provider.of<SettingsViewModel>(
          context,
          listen: false,
        );
        settingsVM.updateAnnualExpenseCalculationMode(mode);
      },
    );
  }
}
