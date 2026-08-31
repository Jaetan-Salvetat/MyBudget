import 'package:mybudget/core/constants/quick_add_schema.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_prompt.dart';

class NanoQuickAddPrompt implements QuickAddPrompt {
  NanoQuickAddPrompt(this._nodes);

  final List<TaxonomyNode> _nodes;

  String? _catalogue;

  @override
  String forInput(String text, {required bool isRetry}) {
    final buffer = StringBuffer()
      ..writeln('## Tâche')
      ..writeln('Ranger une dépense ou un revenu dans une catégorie.')
      ..writeln()
      ..writeln('## Règles')
      ..writeln('- Le slug le plus précis de la liste.')
      ..writeln(
        '- Marque ou enseigne : sers-toi de ce que tu sais d\'elle pour la '
        'ranger.',
      )
      ..writeln('- Rien ne colle : ${QuickAddSchema.fallbackExpenseSlug}.')
      ..writeln(
        '- recurrence : "${QuickAddSchema.recurringLabel}" si ça revient '
        'chaque mois, sinon "${QuickAddSchema.oneTimeLabel}".',
      )
      ..writeln('- name : la saisie au propre, sans rien ajouter.')
      ..writeln(
        '- alternatives : jusqu\'à ${QuickAddSchema.maxAlternatives} slugs '
        'voisins, vide si le choix est net.',
      )
      ..writeln()
      ..writeln('## Catégories')
      ..writeln(_catalogueOfSlugs())
      ..writeln()
      ..writeln('## Exemples')
      ..writeln(
        'salaire → salaire.salaire_net · ${QuickAddSchema.recurringLabel} · '
        '"Salaire"',
      )
      ..writeln(
        'virement mamie → transfert.virement_recu · '
        '${QuickAddSchema.oneTimeLabel} · "Virement mamie"',
      )
      ..writeln(
        'netflix → loisirs.streaming · ${QuickAddSchema.recurringLabel} · '
        '"Netflix"',
      )
      ..writeln(
        'resto italien → restauration.restaurant · '
        '${QuickAddSchema.oneTimeLabel} · "Resto italien"',
      )
      ..writeln(
        'carrefour → alimentation.supermarche · '
        '${QuickAddSchema.oneTimeLabel} · "Carrefour"',
      );

    if (isRetry) {
      buffer
        ..writeln()
        ..writeln('## Correction')
        ..writeln('Ta réponse précédente était inexploitable. Recommence.');
    }

    return (buffer
          ..writeln()
          ..writeln('## Saisie')
          ..writeln(text))
        .toString();
  }

  String _catalogueOfSlugs() {
    return _catalogue ??= _nodes.map((node) => node.slug).join(', ');
  }
}
