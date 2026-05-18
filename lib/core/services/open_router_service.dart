import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openai_dart/openai_dart.dart';

import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/quick_add_result_model.dart';

class OpenRouterService {
  static const String _model = 'google/gemma-4-31b-it';
  static const String _baseUrl = 'https://openrouter.ai/api/v1';

  final OpenAIClient _client;

  OpenRouterService()
      : _client = OpenAIClient.withApiKey(
          dotenv.env['OPENROUTER_API_KEY'] ?? '',
          baseUrl: _baseUrl,
        );

  String _buildSystemPrompt(List<CategoryModel> categories) {
    final categoriesJson = categories
        .map((c) =>
            '{"id": ${c.id}, "name": "${c.name}", "icon": "${c.icon}", "color": "${CategoryDefaults.colorToHex(c.color)}"}')
        .join(', ');

    final availableIcons = CategoryDefaults.iconNames.join(', ');

    final availableColors = CategoryDefaults.colors
        .map(CategoryDefaults.colorToHex)
        .join(', ');

    return 'Tu es un assistant de catégorisation de dépenses.\n'
        'Catégories existantes : [$categoriesJson]\n'
        'Icônes disponibles : [$availableIcons]\n'
        'Couleurs disponibles (hex) : [$availableColors]\n'
        'Règles :\n'
        '1. Extrais le nom, le montant et la fréquence\n'
        '2. Si une catégorie existante correspond → categoryId (et newCategory/newCategoryIcon/newCategoryColor = null)\n'
        '3. Sinon → newCategory = "<nom>", newCategoryIcon = icône la plus pertinente, newCategoryColor = couleur hex la plus pertinente (et categoryId = null)\n'
        '4. Fréquence = "Ponctuel" sauf si "mensuel" ou "annuel" précisé';
  }

  Future<QuickAddResultModel> parseExpense(
    String input,
    List<CategoryModel> categories,
  ) async {
    try {
      final response = await _client.chat.completions.create(
        ChatCompletionCreateRequest(
          model: _model,
          temperature: 0.1,
          messages: [
            ChatMessage.system(_buildSystemPrompt(categories)),
            ChatMessage.user(input),
          ],
          responseFormat: ResponseFormat.jsonSchema(
            name: 'expense',
            strict: true,
            schema: {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'amount': {'type': 'number'},
                'categoryId': {'type': ['integer', 'null']},
                'newCategory': {'type': ['string', 'null']},
                'newCategoryIcon': {'type': ['string', 'null']},
                'newCategoryColor': {'type': ['string', 'null']},
                'frequency': {
                  'type': 'string',
                  'enum': ['Ponctuel', 'Mensuel', 'Annuel'],
                },
              },
              'required': [
                'name',
                'amount',
                'frequency',
                'categoryId',
                'newCategory',
                'newCategoryIcon',
                'newCategoryColor',
              ],
              'additionalProperties': false,
            },
          ),
        ),
      );

      final content = response.text;
      if (content == null || content.isEmpty) {
        throw const QuickAddParseException();
      }

      final json = jsonDecode(content) as Map<String, dynamic>;
      return QuickAddResultModel.fromJson(json);
    } on SocketException {
      throw const QuickAddNetworkException();
    } on QuickAddException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('429')) {
        throw const QuickAddApiException(
          message: 'Service temporairement surchargé',
        );
      }
      throw QuickAddApiException(message: e.toString());
    }
  }
}
