import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openai_dart/openai_dart.dart';

import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/core/services/expense_prompt_builder.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/quick_add_result_model.dart';

class OpenRouterService {
  static const String _model = 'deepseek/deepseek-v4-flash';
  static const String _baseUrl = 'https://openrouter.ai/api/v1';

  final OpenAIClient _client;

  OpenRouterService()
      : _client = OpenAIClient.withApiKey(
          dotenv.env['OPENROUTER_API_KEY'] ?? '',
          baseUrl: _baseUrl,
        );

  String _buildSystemPrompt(
    List<CategoryModel> categories,
    List<ExpenseModel> recurringExpenses,
  ) {
    return ExpensePromptBuilder.build(categories, recurringExpenses);
  }

  Future<QuickAddResultModel> parseExpense(
    String input,
    List<CategoryModel> categories, {
    List<ExpenseModel> recurringExpenses = const [],
  }) async {
    try {
      final response = await _client.chat.completions.create(
        ChatCompletionCreateRequest(
          model: _model,
          temperature: 0.1,
          messages: [
            ChatMessage.system(
              _buildSystemPrompt(categories, recurringExpenses),
            ),
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
