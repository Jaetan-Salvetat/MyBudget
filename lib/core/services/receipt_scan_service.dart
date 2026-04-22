import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/models/scanned_item_model.dart';

class ReceiptScanService {
  static const _modelName = 'gemini-3-flash-preview';

  late final GenerativeModel _model;

  ReceiptScanService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY manquante dans le fichier .env');
    }

    _model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _buildResponseSchema(),
      ),
    );
  }

  Future<ReceiptScanResultModel> extractItems(
    Uint8List imageBytes,
    List<CategoryModel> categories,
  ) async {
    final categoryNames = categories.map((c) => c.name).toList();
    final prompt = _buildPrompt(categoryNames);

    try {
      final response = await _model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ]);

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('Réponse vide de Gemini');
      }

      return _parseResponse(text, categories);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw Exception('Impossible d\'analyser le ticket : $e');
    }
  }

  String _buildPrompt(List<String> categoryNames) {
    final categoriesJson = jsonEncode(categoryNames);
    return '''
Tu es un assistant qui extrait les articles d'un ticket de caisse ou d'une facture.

Catégories disponibles : $categoriesJson

Règles :
- "amount" : toujours positif, en euros. Si quantité > 1, retourne le prix total (unitaire × quantité)
- "date" : format YYYY-MM-DD. null si illisible
- "category" : doit correspondre exactement à une catégorie disponible. null si aucune ne correspond
- "store_name" : nom du commerce. null si illisible
- Ignore les totaux, sous-totaux, TVA, remises et moyens de paiement
- Chaque article = une entrée distincte''';
  }

  Schema _buildResponseSchema() {
    return Schema.object(
      properties: {
        'store_name': Schema.string(nullable: true),
        'date': Schema.string(nullable: true),
        'items': Schema.array(
          items: Schema.object(
            properties: {
              'name': Schema.string(),
              'amount': Schema.number(),
              'category': Schema.string(nullable: true),
            },
            requiredProperties: ['name', 'amount'],
          ),
        ),
      },
      requiredProperties: ['items'],
    );
  }

  ReceiptScanResultModel _parseResponse(
    String jsonText,
    List<CategoryModel> categories,
  ) {
    final Map<String, dynamic> json = jsonDecode(jsonText) as Map<String, dynamic>;

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
