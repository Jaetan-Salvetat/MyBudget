import 'package:mybudget/core/constants/quick_add_schema.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_prompt.dart';

class CloudQuickAddPrompt implements QuickAddPrompt {
  CloudQuickAddPrompt(this._nodes);

  final List<TaxonomyNode> _nodes;

  String? _catalogue;

  String _catalogueOfCategories() {
    if (_catalogue != null) return _catalogue!;

    final byGroup = <TaxonomyGroup, List<TaxonomyNode>>{};
    for (final node in _nodes) {
      byGroup.putIfAbsent(node.group, () => []).add(node);
    }

    final buffer = StringBuffer();
    for (final entry in byGroup.entries) {
      final kind = entry.key.type == TransactionType.income
          ? 'revenu'
          : 'dépense';
      final leaves = entry.value
          .map((node) => '${node.slug} = ${node.label}')
          .join(' · ');
      buffer.writeln('${entry.key.label} ($kind) : $leaves');
    }

    return _catalogue = buffer.toString();
  }

  @override
  String forInput(String text, {required bool isRetry}) {
    final buffer = StringBuffer()
      ..writeln(
        'Tu ranges une saisie de dépense ou de revenu dans une taxonomie '
        'fermée. Tu réponds uniquement avec le schéma demandé.',
      )
      ..writeln()
      ..writeln('Règles :')
      ..writeln(
        '- "category_slug" : la feuille la plus précise du catalogue. '
        'Un revenu se range sous une catégorie de revenu, une dépense sous '
        'une catégorie de dépense.',
      )
      ..writeln(
        '- Si rien ne correspond vraiment, prends $QuickAddSchema.fallbackExpenseSlug plutôt '
        'que de forcer une catégorie voisine.',
      )
      ..writeln(
        '- "alternatives" : les $QuickAddSchema.maxAlternatives feuilles les plus proches '
        'après celle retenue, sans la répéter. Liste vide si le choix est net.',
      )
      ..writeln(
        '- "recurrence" : "$QuickAddSchema.recurringLabel" pour un abonnement, un loyer, une '
        'assurance, un salaire — ce qui revient chaque mois. Sinon '
        '"$QuickAddSchema.oneTimeLabel". Dans le doute, "$QuickAddSchema.oneTimeLabel".',
      )
      ..writeln(
        '- "name" : la saisie remise au propre, capitalisée, dans la langue '
        'de la saisie. Corrige les fautes et développe une abréviation '
        'seulement si elle est sans ambiguïté. N\'ajoute rien qui ne soit '
        'pas dans la saisie.',
      )
      ..writeln(
        '- Le montant et la date ont déjà été retirés de la saisie. '
        'N\'en invente aucun, et n\'en remets pas dans "name".',
      )
      ..writeln()
      ..writeln('Exemples :')
      ..writeln(
        'resto italien → restauration.restaurant · $QuickAddSchema.oneTimeLabel · '
        '"Resto italien"',
      )
      ..writeln(
        'netflix → loisirs.streaming · $QuickAddSchema.recurringLabel · "Netflix"',
      )
      ..writeln(
        'virement mamie → transfert.virement_recu · $QuickAddSchema.oneTimeLabel · '
        '"Virement mamie"',
      )
      ..writeln()
      ..writeln('Catalogue :')
      ..write(_catalogueOfCategories());

    if (isRetry) {
      buffer
        ..writeln()
        ..writeln(
          'Ta réponse précédente était inexploitable. Reprends en n\'utilisant '
          'que des valeurs du catalogue ci-dessus.',
        );
    }

    buffer
      ..writeln()
      ..writeln('Saisie : "$text"');

    return buffer.toString();
  }
}
