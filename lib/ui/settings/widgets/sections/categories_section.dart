import 'package:flutter/material.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';
import 'package:mybudget/ui/settings/widgets/categories_bottom_sheet.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Catégories',
      children: [
        SettingsTile(
          title: 'Gérer les catégories',
          subtitle: 'Ajouter, modifier ou supprimer des catégories',
          leading: const Icon(Icons.category),
          onTap: () => CategoriesBottomSheet.show(context: context),
        ),
      ],
    );
  }
}
