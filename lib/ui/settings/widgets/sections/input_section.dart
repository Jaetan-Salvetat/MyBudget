import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/ui/settings/screens/beneficiaries_screen.dart';
import 'package:mybudget/ui/settings/screens/categories_screen.dart';

class InputSection extends StatelessWidget {
  const InputSection({super.key});

  @override
  Widget build(BuildContext context) {
    return FrostedListSection(
      label: 'Saisie',
      tiles: [
        FrostedListTile(
          title: 'Gérer les catégories',
          subtitle: 'Renommer, changer icône et couleur',
          leading: const FrostedListAvatar(icon: Symbols.category_rounded),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()),
          ),
        ),
        FrostedListTile(
          title: 'Gérer les bénéficiaires',
          subtitle: 'Ajouter ou supprimer des bénéficiaires',
          leading: const FrostedListAvatar(icon: Symbols.people_rounded),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const BeneficiariesScreen(),
            ),
          ),
        ),
      ],
    );
  }
}
