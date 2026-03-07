import 'package:flutter/material.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';
import 'package:mybudget/ui/settings/widgets/beneficiaries_bottom_sheet.dart';

class BeneficiariesSection extends StatelessWidget {
  const BeneficiariesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Bénéficiaires',
      children: [
        SettingsTile(
          title: 'Gérer les bénéficiaires',
          subtitle: 'Ajouter ou supprimer des bénéficiaires',
          leading: const Icon(Icons.people_outline),
          onTap: () => BeneficiariesBottomSheet.show(context: context),
        ),
      ],
    );
  }
}
