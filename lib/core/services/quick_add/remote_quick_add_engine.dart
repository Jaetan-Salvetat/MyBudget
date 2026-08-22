import 'dart:convert';

import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/quick_add/price_parser_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';
import 'package:mybudget/core/services/quick_add/quick_add_engine.dart';

/// Le moteur distant. Il ne voit jamais le montant : celui-ci est extrait
/// localement et retiré du texte avant l'envoi, ce qui supprime d'un coup les
/// montants hallucinés et les séparateurs décimaux inversés.
class RemoteQuickAddEngine implements QuickAddEngine {
  RemoteQuickAddEngine({
    required AiChatClient client,
    required CategoryTaxonomyService taxonomy,
  }) : _client = client,
       _taxonomy = taxonomy;

  /// Une saisie d'ajout rapide tient en une ligne. Au-delà c'est un collage :
  /// on borne le coût et ce qui sort du téléphone.
  static const int maxInputLength = 280;

  /// Une seule reprise : si le modèle sort deux fois de la taxonomie, la
  /// réponse locale est meilleure que d'insister.
  static const int maxAttempts = 2;

  static const String _recurringLabel = 'fixe';
  static const String _oneTimeLabel = 'ponctuel';
  static const String _schemaName = 'quick_add';
  static const int _maxAlternatives = 3;

  /// Le refuge quand rien ne colle : mieux vaut « Autre » qu'une catégorie
  /// voisine qui obligera l'utilisateur à corriger.
  static const String _fallbackExpenseSlug = 'divers.autre';

  final AiChatClient _client;
  final CategoryTaxonomyService _taxonomy;

  List<TaxonomyNode>? _selectableNodes;
  String? _catalogue;

  @override
  Future<QuickAddClassification> classify(String input) async {
    final priceResult = PriceParserService.parse(input);
    final cleanedText = priceResult == null || priceResult.remaining.isEmpty
        ? input
        : priceResult.remaining;

    final slugs = _nodes().map((node) => node.slug).toList();
    final schema = _schemaFor(slugs);

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      final raw = await _client.complete(
        prompt: _promptFor(_truncate(cleanedText), isRetry: attempt > 1),
        schemaName: _schemaName,
        schema: schema,
      );

      final classification = _parse(raw, cleanedText, priceResult?.price);
      if (classification != null) return classification;
    }

    throw const AiRequestException(AiRequestFailure.malformedResponse);
  }

  /// L'énumération du schéma et le catalogue du prompt sortent de la même
  /// liste : ils ne peuvent pas diverger.
  List<TaxonomyNode> _nodes() {
    return _selectableNodes ??= _taxonomy.leaves
        .where((node) => !node.isDeprecated && node.aliasOf == null)
        .toList();
  }

  /// Les slugs seuls sont ambigus (`divers.tabac_jeux`, `finance.retrait_dab`).
  /// Le libellé lève le doute, et ce bloc est stable d'un appel à l'autre :
  /// placé en tête, il se met en cache côté fournisseur.
  String _catalogueOfCategories() {
    if (_catalogue != null) return _catalogue!;

    final byGroup = <TaxonomyGroup, List<TaxonomyNode>>{};
    for (final node in _nodes()) {
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

  static String _truncate(String text) => text.length <= maxInputLength
      ? text
      : text.substring(0, maxInputLength);

  Map<String, dynamic> _schemaFor(List<String> slugs) {
    return {
      'type': 'object',
      'properties': {
        'category_slug': {'type': 'string', 'enum': slugs},
        'alternatives': {
          'type': 'array',
          'maxItems': _maxAlternatives,
          'items': {'type': 'string', 'enum': slugs},
        },
        'recurrence': {
          'type': 'string',
          'enum': [_oneTimeLabel, _recurringLabel],
        },
        'name': {'type': 'string'},
      },
      'required': ['category_slug', 'alternatives', 'recurrence', 'name'],
      'additionalProperties': false,
    };
  }

  String _promptFor(String text, {required bool isRetry}) {
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
        '- Si rien ne correspond vraiment, prends $_fallbackExpenseSlug plutôt '
        'que de forcer une catégorie voisine.',
      )
      ..writeln(
        '- "alternatives" : les $_maxAlternatives feuilles les plus proches '
        'après celle retenue, sans la répéter. Liste vide si le choix est net.',
      )
      ..writeln(
        '- "recurrence" : "$_recurringLabel" pour un abonnement, un loyer, une '
        'assurance, un salaire — ce qui revient chaque mois. Sinon '
        '"$_oneTimeLabel". Dans le doute, "$_oneTimeLabel".',
      )
      ..writeln(
        '- "name" : la saisie remise au propre, capitalisée, dans la langue '
        'de la saisie. Corrige les fautes et développe une abréviation '
        'seulement si elle est sans ambiguïté. N\'ajoute rien qui ne soit '
        'pas dans la saisie.',
      )
      ..writeln(
        '- Le montant a déjà été retiré de la saisie. N\'en invente aucun, '
        'et n\'en remets pas dans "name".',
      )
      ..writeln()
      ..writeln('Exemples :')
      ..writeln(
        'resto italien → restauration.restaurant · $_oneTimeLabel · '
        '"Resto italien"',
      )
      ..writeln('netflix → loisirs.streaming · $_recurringLabel · "Netflix"')
      ..writeln('virement mamie → transfert.virement_recu · $_oneTimeLabel · '
          '"Virement mamie"')
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

    // La saisie ferme le prompt : tout ce qui précède est identique d'un
    // appel à l'autre, donc réutilisable par le cache du fournisseur.
    buffer
      ..writeln()
      ..writeln('Saisie : "$text"');

    return buffer.toString();
  }

  /// Null quand la réponse est inexploitable : l'appelant relance, il ne
  /// devine pas.
  QuickAddClassification? _parse(
    String raw,
    String cleanedText,
    double? amount,
  ) {
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }

    final slug = payload['category_slug'];
    if (slug is! String) return null;

    final category = _taxonomy.resolve(slug);
    if (category == null || category.isDeprecated) return null;

    final recurrence = payload['recurrence'];
    final name = payload['name'];

    return QuickAddClassification(
      type: category.group.type,
      category: category,
      frequency: recurrence == _recurringLabel
          ? Frequency.monthly
          : Frequency.oneTime,
      amount: amount,
      name: name is String && name.trim().isNotEmpty
          ? name.trim()
          : _fallbackName(cleanedText, category),
      typeConfidence: 1,
      categoryConfidence: 1,
      recurrenceConfidence: 1,
      categorySuggestions: _suggestions(payload['alternatives'], slug),
      cleanedText: cleanedText,
    );
  }

  List<String> _suggestions(Object? alternatives, String chosenSlug) {
    if (alternatives is! List) return const [];
    return alternatives
        .whereType<String>()
        .where((slug) => slug != chosenSlug && _taxonomy.resolve(slug) != null)
        .take(_maxAlternatives)
        .toList();
  }

  static String _fallbackName(String cleanedText, TaxonomyNode category) {
    final trimmed = cleanedText.trim();
    if (trimmed.isEmpty) return category.label;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}
