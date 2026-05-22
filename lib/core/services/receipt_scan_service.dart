import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openai_dart/openai_dart.dart';

import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/models/scanned_item_model.dart';

class ReceiptScanService {
  static const String _model = 'google/gemini-2.0-flash-lite-001';
  static const String _baseUrl = 'https://openrouter.ai/api/v1';

  final OpenAIClient _client;

  ReceiptScanService()
      : _client = OpenAIClient.withApiKey(
          dotenv.env['OPENROUTER_API_KEY'] ?? '',
          baseUrl: _baseUrl,
        );

  Future<ReceiptScanResultModel> extractItems(
    Uint8List imageBytes,
    List<CategoryModel> categories,
  ) async {
    final categoryNames = categories.map((c) => c.name).toList();
    final prompt = _buildPrompt(categoryNames);
    final base64Image = base64Encode(imageBytes);

    final response = await _client.chat.completions.create(
      ChatCompletionCreateRequest(
        model: _model,
        temperature: 0.1,
        messages: [
          ChatMessage.user([
            ContentPart.text(prompt),
            ContentPart.imageBase64(
              data: base64Image,
              mediaType: 'image/jpeg',
            ),
          ]),
        ],
        responseFormat: ResponseFormat.jsonSchema(
          name: 'receipt',
          strict: true,
          schema: {
            'type': 'object',
            'properties': {
              'store_name': {'type': ['string', 'null']},
              'date': {'type': ['string', 'null']},
              'items': {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'properties': {
                    'name': {'type': 'string'},
                    'amount': {'type': 'number'},
                    'discount': {'type': 'number'},
                    'category': {'type': ['string', 'null']},
                  },
                  'required': ['name', 'amount', 'discount'],
                  'additionalProperties': false,
                },
              },
            },
            'required': ['store_name', 'date', 'items'],
            'additionalProperties': false,
          },
        ),
      ),
    );

    final content = response.text;
    if (content == null || content.isEmpty) {
      throw Exception('Réponse vide du service');
    }

    return _parseResponse(content, categories);
  }

  String _buildPrompt(List<String> categoryNames) {
    final categoriesJson = jsonEncode(categoryNames);
    return 'Tu es un assistant qui extrait les articles d\'un ticket de caisse ou d\'une facture.\n'
        '\n'
        'Catégories disponibles : $categoriesJson\n'
        '\n'
        'Règles :\n'
        '- "amount" : prix original de l\'article, toujours positif, en euros. '
        'Si quantité > 1, retourne le prix total (unitaire × quantité) avant remise\n'
        '- "discount" : montant de la remise ou promotion appliquée à cet article, en euros. '
        '0 si aucune remise\n'
        '- "date" : format YYYY-MM-DD. null si illisible\n'
        '- "category" : doit correspondre exactement à une catégorie disponible. '
        'null si aucune ne correspond\n'
        '- "store_name" : nom du commerce. null si illisible\n'
        '- Les remises globales (coupons, carte fidélité) qui ne sont pas rattachées '
        'à un article précis doivent être ignorées\n'
        '- Ignore les totaux, sous-totaux, TVA et moyens de paiement\n'
        '- Chaque article = une entrée distincte';
  }

  ReceiptScanResultModel _parseResponse(
    String jsonText,
    List<CategoryModel> categories,
  ) {
    final Map<String, dynamic> json =
        jsonDecode(jsonText) as Map<String, dynamic>;

    final String? storeName = json['store_name'] as String?;
    final String? dateStr = json['date'] as String?;
    final DateTime? date = dateStr != null ? DateTime.tryParse(dateStr) : null;

    final List<dynamic> itemsJson = json['items'] as List<dynamic>? ?? [];

    final items = itemsJson.map((item) {
      final Map<String, dynamic> itemMap = item as Map<String, dynamic>;
      final String? categoryName = itemMap['category'] as String?;
      final int? categoryId = _matchCategory(categoryName, categories);

      return ScannedItemModel(
        name: itemMap['name'] as String? ?? '',
        amount: (itemMap['amount'] as num?)?.toDouble() ?? 0.0,
        discount: (itemMap['discount'] as num?)?.toDouble() ?? 0.0,
        categoryName: categoryName,
        categoryId: categoryId,
      );
    }).toList();

    return ReceiptScanResultModel(
      storeName: storeName,
      date: date,
      items: items,
    );
  }

  int? _matchCategory(String? name, List<CategoryModel> categories) {
    if (name == null) return null;
    final lowerName = name.toLowerCase();
    for (final category in categories) {
      if (category.name.toLowerCase() == lowerName) {
        return category.id;
      }
    }
    return null;
  }
}
