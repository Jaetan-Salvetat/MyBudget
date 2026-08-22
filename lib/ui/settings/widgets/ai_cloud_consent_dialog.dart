import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mybudget/core/enums/ai_provider.dart';

/// Dit exactement ce qui sort du téléphone, avant le premier appel. Le contenu
/// est vérifiable : c'est littéralement ce que le moteur distant envoie.
class AiCloudConsentDialog extends StatelessWidget {
  const AiCloudConsentDialog({required this.provider, super.key});

  final AiProvider provider;

  static Future<bool> show(BuildContext context, AiProvider provider) async {
    final accepted = await showFrostedDialog<bool>(
      context: context,
      builder: (_) => AiCloudConsentDialog(provider: provider),
    );
    return accepted ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FrostedDialog(
      title: 'Ce qui sera envoyé à ${provider.label}',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ConsentLine(
            icon: Symbols.north_east_rounded,
            text:
                'Le texte de votre saisie, montant retiré. '
                '« resto italien 25 » part en « resto italien ».',
          ),
          SizedBox(height: FrostedSpacing.sp3),
          _ConsentLine(
            icon: Symbols.north_east_rounded,
            text: 'La liste des noms de vos catégories.',
          ),
          SizedBox(height: FrostedSpacing.sp3),
          _ConsentLine(
            icon: Symbols.block_rounded,
            text:
                'Aucun montant, aucun solde, aucun historique, '
                'aucun bénéficiaire.',
          ),
          SizedBox(height: FrostedSpacing.sp3),
          _ConsentLine(
            icon: Symbols.key_rounded,
            text:
                'La clé est conservée dans le trousseau du téléphone, '
                'jamais transmise ailleurs.',
          ),
        ],
      ),
      actions: [
        FrostedButton.text(
          label: 'Annuler',
          onPressed: () => Navigator.pop(context, false),
        ),
        FrostedButton.text(
          label: 'J\'ai compris',
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}

class _ConsentLine extends StatelessWidget {
  const _ConsentLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colors.onSurfaceVariant),
        const SizedBox(width: FrostedSpacing.sp3),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
