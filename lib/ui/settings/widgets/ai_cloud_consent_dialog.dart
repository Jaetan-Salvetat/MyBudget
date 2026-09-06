import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/ui/settings/widgets/settings_note.dart';

class AiCloudConsentDialog extends StatelessWidget {
  const AiCloudConsentDialog({required this.provider, super.key});

  static const String quickAddWarning =
      'Ajout rapide : le texte de votre saisie, montant retiré. '
      '« resto italien 25 » part en « resto italien ».';

  static const String categoriesWarning =
      'Ajout rapide : la liste des noms de vos catégories.';

  static const String scanWarning =
      'Scan : la photo entière du ticket, telle quelle. L\'enseigne, la date, '
      'les articles et les montants en font partie.';

  static const String withheldWarning =
      'Aucun solde, aucun historique, aucune autre dépense, '
      'aucun bénéficiaire.';

  static const String freePlanWarning =
      'Offre gratuite de Google : vos envois sont conservés et servent à '
      'améliorer leurs modèles. L\'offre payante ne le fait pas.';

  static const String keyStorageNote =
      'La clé est conservée dans le trousseau du téléphone, '
      'jamais transmise ailleurs.';

  static const double maxBodyHeightRatio = 0.6;

  final AiProvider provider;

  static Future<bool> show(BuildContext context, AiProvider provider) async {
    final bool? accepted = await showFrostedDialog<bool>(
      context: context,
      builder: (_) => AiCloudConsentDialog(provider: provider),
    );
    return accepted ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FrostedDialog(
      title: 'Ce qui sera envoyé à ${provider.label}',
      body: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * maxBodyHeightRatio,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SettingsNote.prominent(
                icon: Symbols.north_east_rounded,
                text: quickAddWarning,
              ),
              SizedBox(height: FrostedSpacing.sp3),
              SettingsNote.prominent(
                icon: Symbols.north_east_rounded,
                text: categoriesWarning,
              ),
              SizedBox(height: FrostedSpacing.sp3),
              SettingsNote.prominent(
                icon: Symbols.photo_camera_rounded,
                text: scanWarning,
              ),
              SizedBox(height: FrostedSpacing.sp3),
              SettingsNote.prominent(
                icon: Symbols.block_rounded,
                text: withheldWarning,
              ),
              SizedBox(height: FrostedSpacing.sp3),
              SettingsNote.prominent(
                icon: Symbols.warning_rounded,
                text: freePlanWarning,
              ),
              SizedBox(height: FrostedSpacing.sp3),
              SettingsNote.prominent(
                icon: Symbols.key_rounded,
                text: keyStorageNote,
              ),
            ],
          ),
        ),
      ),
      actions: [
        FrostedButton.text(
          label: 'Annuler',
          onPressed: () => Navigator.pop(context, false),
        ),
        FrostedButton.text(
          label: 'Activer',
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}
