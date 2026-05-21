import 'dart:convert';

import 'package:flutter_litert_lm/flutter_litert_lm.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
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
    final parseResult = await _runParse(input, categories, recurringExpenses);

    if (parseResult.newCategory != null) {
      final style = await _runCategorize(parseResult.newCategory!);
      return parseResult.copyWith(
        newCategoryIcon: style.icon,
        newCategoryColor: style.color,
        newCategoryScope: style.scope,
      );
    }

    return parseResult;
  }

  Future<QuickAddResultModel> _runParse(
    String input,
    List<CategoryModel> categories,
    List<ExpenseModel> recurringExpenses,
  ) async {
    final systemPrompt = ExpensePromptBuilder.buildParseLocal(
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
        'Invalid JSON. Respond ONLY with the JSON object, no surrounding text.',
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

  Future<_CategoryStyle> _runCategorize(String categoryName) async {
    final systemPrompt = ExpensePromptBuilder.buildCategorize(categoryName);

    LiteLmConversation? conversation;
    try {
      conversation = await _engineService.engine.createConversation(
        LiteLmConversationConfig(
          systemInstruction: systemPrompt,
          samplerConfig: const LiteLmSamplerConfig(temperature: 0.1),
        ),
      );

      final response = await conversation.sendMessage(categoryName);
      final json = _extractJson(response.text);

      if (json != null) {
        return _parseCategoryStyle(json);
      }

      return _CategoryStyle.fallback;
    } catch (_) {
      return _CategoryStyle.fallback;
    } finally {
      await conversation?.dispose();
    }
  }

  _CategoryStyle _parseCategoryStyle(Map<String, dynamic> json) {
    final icon = json['icon'] as String?;
    final color = json['color'] as String?;
    final scope = json['scope'] as String? ?? '';

    final validIcon =
        icon != null && CategoryDefaults.icons.containsKey(icon)
            ? icon
            : CategoryDefaults.defaultIcon;
    final validColor =
        color != null && CategoryDefaults.hexToColor(color) != null
            ? color
            : CategoryDefaults.colorToHex(CategoryDefaults.defaultColor);

    return _CategoryStyle(icon: validIcon, color: validColor, scope: scope);
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

class _CategoryStyle {
  final String icon;
  final String color;
  final String scope;

  const _CategoryStyle({
    required this.icon,
    required this.color,
    this.scope = '',
  });

  static final fallback = _CategoryStyle(
    icon: CategoryDefaults.defaultIcon,
    color: CategoryDefaults.colorToHex(CategoryDefaults.defaultColor),
  );
}
