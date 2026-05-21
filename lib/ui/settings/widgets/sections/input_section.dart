import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';
import 'package:mybudget/ui/settings/widgets/categories_bottom_sheet.dart';
import 'package:mybudget/ui/settings/widgets/beneficiaries_bottom_sheet.dart';

class InputSection extends StatelessWidget {
  const InputSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Saisie',
      children: [
        SettingsTile(
          title: 'Gérer les catégories',
          subtitle: 'Ajouter, modifier ou supprimer des catégories',
          leading: const Icon(Symbols.category_rounded),
          onTap: () => CategoriesBottomSheet.show(context: context),
        ),
        SettingsTile(
          title: 'Gérer les bénéficiaires',
          subtitle: 'Ajouter ou supprimer des bénéficiaires',
          leading: const Icon(Symbols.people_rounded),
          onTap: () => BeneficiariesBottomSheet.show(context: context),
        ),
      ],
    );
  }
}
