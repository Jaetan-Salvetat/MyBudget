import 'dart:convert';
import 'package:mybudget/core/constants/quick_add_schema.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';
import 'package:mybudget/core/services/quick_add/quick_add_engine.dart';
import 'package:mybudget/core/services/quick_add/quick_add_prompt.dart';
import 'package:mybudget/core/services/quick_add/quick_add_text_reader.dart';
import 'package:mybudget/core/time/clock.dart';

class PromptQuickAddEngine implements QuickAddEngine {
  PromptQuickAddEngine({
    required this._client,
    required this._taxonomy,
    required this._prompt,
    required this._clock,
  });

  static const int maxInputLength = 280;

  static const int maxAttempts = 2;

  final AiChatClient _client;
  final CategoryTaxonomyService _taxonomy;
  final QuickAddPrompt _prompt;
  final Clock _clock;

  @override
  Future<QuickAddClassification> classify(String input) async {
    final facts = QuickAddTextReader.read(input, today: _clock());
    final cleanedText = facts.modelText;

    final slugs = _taxonomy.selectableLeaves.map((node) => node.slug).toList();
    final schema = _schemaFor(slugs);

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      final raw = await _client.complete(
        prompt: _prompt.forInput(_truncate(cleanedText), isRetry: attempt > 1),
        schemaName: QuickAddSchema.name,
        schema: schema,
      );

      final classification = _parse(raw, cleanedText, facts);
      if (classification != null) return classification;
    }

    throw const AiRequestException(AiRequestFailure.malformedResponse);
  }

  static String _truncate(String text) =>
      text.length <= maxInputLength ? text : text.substring(0, maxInputLength);

  Map<String, dynamic> _schemaFor(List<String> slugs) {
    return {
      'type': 'object',
      'properties': {
        'category_slug': {'type': 'string', 'enum': slugs},
        'alternatives': {
          'type': 'array',
          'maxItems': QuickAddSchema.maxAlternatives,
          'items': {'type': 'string', 'enum': slugs},
        },
        'recurrence': {
          'type': 'string',
          'enum': [QuickAddSchema.oneTimeLabel, QuickAddSchema.recurringLabel],
        },
        'name': {'type': 'string'},
      },
      'required': ['category_slug', 'alternatives', 'recurrence', 'name'],
      'additionalProperties': false,
    };
  }

  QuickAddClassification? _parse(
    String raw,
    String cleanedText,
    QuickAddTextFacts facts,
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
      frequency: recurrence == QuickAddSchema.recurringLabel
          ? Frequency.monthly
          : Frequency.oneTime,
      date: facts.date,
      hasWrittenDate: facts.hasWrittenDate,
      amount: facts.amount,
      name: name is String && name.trim().isNotEmpty
          ? name.trim()
          : _fallbackName(facts.remaining, category),
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
        .take(QuickAddSchema.maxAlternatives)
        .toList();
  }

  static String _fallbackName(String cleanedText, TaxonomyNode category) {
    final trimmed = cleanedText.trim();
    if (trimmed.isEmpty) return category.label;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}
