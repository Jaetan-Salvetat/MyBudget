import 'dart:convert';

import 'package:flutter_litert_lm/flutter_litert_lm.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/core/services/expense_prompt_builder.dart';
import 'package:mybudget/core/services/litert_engine_service.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/quick_add_result_model.dart';

class LocalInferenceService {
  final LitertEngineService _engineService;

  LocalInferenceService(this._engineService);

  Future<QuickAddResultModel> parseExpense(
    String input,
    List<CategoryModel> categories, {
    List<ExpenseModel> recurringExpenses = const [],
  }) async {
    final systemPrompt = ExpensePromptBuilder.buildForLocalModel(
      categories,
      recurringExpenses,
    );

    LiteLmConversation? conversation;
    try {
      conversation = await _engineService.engine.createConversation(
        LiteLmConversationConfig(
          systemInstruction: systemPrompt,
          samplerConfig: const LiteLmSamplerConfig(temperature: 0.1),
        ),
      );

      final response = await conversation.sendMessage(input);
      final json = _extractJson(response.text);

      if (json != null) {
        return QuickAddResultModel.fromJson(json);
      }

      final retryResponse = await conversation.sendMessage(
        'Ta réponse n\'était pas du JSON valide. '
        'Réponds uniquement avec le JSON demandé, sans texte autour.',
      );
      final retryJson = _extractJson(retryResponse.text);

      if (retryJson != null) {
        return QuickAddResultModel.fromJson(retryJson);
      }

      throw const QuickAddParseException();
    } on QuickAddException {
      rethrow;
    } catch (e) {
      throw QuickAddApiException(message: 'Erreur IA locale : $e');
    } finally {
      await conversation?.dispose();
    }
  }

  Map<String, dynamic>? _extractJson(String text) {
    try {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) return null;

      final jsonStr = text.substring(start, end + 1);
      final decoded = jsonDecode(jsonStr);

      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }
}
