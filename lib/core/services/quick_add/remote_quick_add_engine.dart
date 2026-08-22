import 'dart:convert';

import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/enums/frequency.dart';
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

  final AiChatClient _client;
  final CategoryTaxonomyService _taxonomy;

  @override
  Future<QuickAddClassification> classify(String input) async {
    final priceResult = PriceParserService.parse(input);
    final cleanedText = priceResult == null || priceResult.remaining.isEmpty
        ? input
        : priceResult.remaining;

    final slugs = _allowedSlugs();
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

  List<String> _allowedSlugs() => _taxonomy.leaves
      .where((node) => !node.isDeprecated && node.aliasOf == null)
      .map((node) => node.slug)
      .toList();

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
        'Tu classes une saisie de dépense ou de revenu dans une taxonomie fermée.',
      )
      ..writeln()
      ..writeln('Saisie : "$text"')
      ..writeln()
      ..writeln('Règles :')
      ..writeln(
        '- "category_slug" : la catégorie la plus précise de la liste autorisée.',
      )
      ..writeln(
        '- "alternatives" : jusqu\'à $_maxAlternatives autres catégories plausibles, sans répéter la première.',
      )
      ..writeln(
        '- "recurrence" : "$_recurringLabel" pour un abonnement ou une charge qui revient chaque mois, sinon "$_oneTimeLabel".',
      )
      ..writeln(
        '- "name" : le libellé de la transaction, corrigé et capitalisé, sans montant ni devise.',
      )
      ..writeln(
        '- La saisie ne contient aucun montant : il a déjà été extrait. N\'en invente pas.',
      );

    if (isRetry) {
      buffer
        ..writeln()
        ..writeln(
          'Ta réponse précédente était inexploitable. Reprends en utilisant '
          'uniquement des valeurs de la liste autorisée.',
        );
    }

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
