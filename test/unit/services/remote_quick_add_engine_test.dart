import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/quick_add/remote_quick_add_engine.dart';

class _ScriptedChatClient implements AiChatClient {
  _ScriptedChatClient(this.responses);

  final List<String> responses;
  final List<String> prompts = [];
  final List<Map<String, dynamic>> schemas = [];

  @override
  Future<String> complete({
    required String prompt,
    required String schemaName,
    required Map<String, dynamic> schema,
    AiImageAttachment? image,
  }) async {
    prompts.add(prompt);
    schemas.add(schema);
    return responses[prompts.length - 1];
  }

  @override
  void close() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CategoryTaxonomyService taxonomy;

  String answer({
    String slug = 'restauration.restaurant',
    String recurrence = 'ponctuel',
    String name = 'Resto italien',
    List<String> alternatives = const ['restauration.fast_food'],
  }) {
    return jsonEncode({
      'category_slug': slug,
      'alternatives': alternatives,
      'recurrence': recurrence,
      'name': name,
    });
  }

  RemoteQuickAddEngine engineWith(_ScriptedChatClient client) =>
      RemoteQuickAddEngine(client: client, taxonomy: taxonomy);

  setUpAll(() async {
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
  });

  group('RemoteQuickAddEngine', () {
    test('reads a well-formed answer', () async {
      final engine = engineWith(_ScriptedChatClient([answer()]));

      final classification = await engine.classify('resto italien 25');

      expect(classification.name, 'Resto italien');
      expect(classification.categorySlug, 'restauration.restaurant');
      expect(classification.type, TransactionType.expense);
      expect(classification.frequency, Frequency.oneTime);
    });

    test('keeps the amount the local parser found', () async {
      final engine = engineWith(_ScriptedChatClient([answer()]));

      expect((await engine.classify('resto italien 25')).amount, 25);
    });

    test('never sends the amount to the service', () async {
      final client = _ScriptedChatClient([answer()]);

      await engineWith(client).classify('resto italien 25');

      expect(client.prompts.single, contains('resto italien'));
      expect(client.prompts.single, isNot(contains('25')));
    });

    test('reads a subscription as a monthly transaction', () async {
      final engine = engineWith(
        _ScriptedChatClient([
          answer(slug: 'loisirs.streaming', recurrence: 'fixe'),
        ]),
      );

      expect(
        (await engine.classify('netflix 13')).frequency,
        Frequency.monthly,
      );
    });

    test('takes the transaction type from the category, not the model', () async {
      final engine = engineWith(
        _ScriptedChatClient([answer(slug: 'salaire.salaire_net')]),
      );

      expect(
        (await engine.classify('salaire 2500')).type,
        TransactionType.income,
      );
    });

    test('constrains the answer to the taxonomy', () async {
      final client = _ScriptedChatClient([answer()]);

      await engineWith(client).classify('resto italien 25');

      final slugs =
          (client.schemas.single['properties']
                  as Map<String, dynamic>)['category_slug']
              as Map<String, dynamic>;
      expect(slugs['enum'], contains('restauration.restaurant'));
    });

    test('truncates a pasted wall of text before sending it', () async {
      final client = _ScriptedChatClient([answer()]);
      final longInput = '${'a' * 400} 25';

      await engineWith(client).classify(longInput);

      expect(
        client.prompts.single,
        contains('a' * RemoteQuickAddEngine.maxInputLength),
      );
      expect(
        client.prompts.single,
        isNot(contains('a' * (RemoteQuickAddEngine.maxInputLength + 1))),
      );
    });

    test('drops alternatives that repeat the chosen category', () async {
      final engine = engineWith(
        _ScriptedChatClient([
          answer(
            alternatives: const [
              'restauration.restaurant',
              'restauration.fast_food',
            ],
          ),
        ]),
      );

      expect(
        (await engine.classify('resto italien 25')).categorySuggestions,
        ['restauration.fast_food'],
      );
    });

    test('retries once when the category is off the taxonomy', () async {
      final client = _ScriptedChatClient([
        answer(slug: 'inventee.categorie'),
        answer(),
      ]);

      final classification = await engineWith(client).classify('resto 25');

      expect(classification.categorySlug, 'restauration.restaurant');
      expect(client.prompts.length, 2);
      expect(client.prompts.last, contains('inexploitable'));
    });

    test('retries once when the answer is not JSON', () async {
      final client = _ScriptedChatClient(['pas du json', answer()]);

      expect(
        (await engineWith(client).classify('resto 25')).categorySlug,
        'restauration.restaurant',
      );
    });

    test('gives up after the retry rather than inventing an answer', () async {
      final client = _ScriptedChatClient([
        answer(slug: 'inventee.categorie'),
        answer(slug: 'encore.inventee'),
      ]);

      await expectLater(
        engineWith(client).classify('resto 25'),
        throwsA(
          isA<AiRequestException>().having(
            (error) => error.failure,
            'failure',
            AiRequestFailure.malformedResponse,
          ),
        ),
      );
      expect(client.prompts.length, RemoteQuickAddEngine.maxAttempts);
    });

    test('falls back on the cleaned text when the name is empty', () async {
      final engine = engineWith(_ScriptedChatClient([answer(name: '  ')]));

      expect((await engine.classify('resto italien 25')).name, 'Resto italien');
    });

    test('closes the prompt with the input, catalogue first', () async {
      final client = _ScriptedChatClient([answer()]);

      await engineWith(client).classify('resto italien 25');

      final prompt = client.prompts.single;
      expect(prompt.indexOf('Catalogue :'), lessThan(prompt.indexOf('Saisie')));
      expect(prompt.trimRight(), endsWith('Saisie : "resto italien"'));
    });

    test('spells out every category with its label', () async {
      final client = _ScriptedChatClient([answer()]);

      await engineWith(client).classify('resto italien 25');

      expect(
        client.prompts.single,
        contains('restauration.restaurant = Restaurant'),
      );
      expect(client.prompts.single, contains('(revenu)'));
    });

    test('every slug the prompt names exists in the taxonomy', () async {
      final client = _ScriptedChatClient([answer()]);

      await engineWith(client).classify('resto 25');

      final quoted = RegExp(r'\b([a-z_]+\.[a-z_]+)\b')
          .allMatches(client.prompts.single)
          .map((match) => match.group(1)!)
          .toSet();
      expect(quoted, isNotEmpty);
      for (final slug in quoted) {
        expect(taxonomy.resolve(slug), isNotNull, reason: slug);
      }
    });
  });
}
