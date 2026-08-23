import 'dart:convert';

import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/models/scanned_item_model.dart';

/// Lit un ticket de caisse. La clé, le fournisseur et le modèle sont ceux de
/// l'ajout rapide : une seule configuration pour les deux fonctions.
class ReceiptScanService {
  ReceiptScanService({required AiChatClient client}) : _client = client;

  static const String _schemaName = 'receipt';

  static const Map<String, dynamic> _schema = {
    'type': 'object',
    'properties': {
      'store_name': {
        'type': ['string', 'null'],
      },
      'date': {
        'type': ['string', 'null'],
      },
      'items': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
            'amount': {'type': 'number'},
            'discount': {'type': 'number'},
            'category': {
              'type': ['string', 'null'],
            },
          },
          'required': ['name', 'amount', 'discount'],
          'additionalProperties': false,
        },
      },
    },
    'required': ['store_name', 'date', 'items'],
    'additionalProperties': false,
  };

  final AiChatClient _client;

  Future<ReceiptScanResultModel> extractItems(
    AiImageAttachment image,
    List<CategoryDisplay> categories,
  ) async {
    final categoryNames = categories.map(_qualifiedName).toList();

    final content = await _client.complete(
      prompt: _buildPrompt(categoryNames),
      schemaName: _schemaName,
      schema: _schema,
      image: image,
    );

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
    List<CategoryDisplay> categories,
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
      final String? categorySlug = matchCategory(categoryName, categories);

      return ScannedItemModel(
        name: itemMap['name'] as String? ?? '',
        amount: (itemMap['amount'] as num?)?.toDouble() ?? 0.0,
        discount: (itemMap['discount'] as num?)?.toDouble() ?? 0.0,
        categoryName: categoryName,
        categorySlug: categorySlug,
      );
    }).toList();

    return ReceiptScanResultModel(
      storeName: storeName,
      date: date,
      items: items,
    );
  }

  static String _qualifiedName(CategoryDisplay category) =>
      '${category.groupLabel} > ${category.label}';

  /// Maps a label produced by the model back to a taxonomy slug.
  ///
  /// Accepts both the qualified form sent in the prompt ("Groupe > Feuille")
  /// and the bare leaf label, since the model drops the prefix at times.
  static String? matchCategory(String? name, List<CategoryDisplay> categories) {
    if (name == null) return null;
    final lowerName = name.toLowerCase();
    for (final category in categories) {
      if (_qualifiedName(category).toLowerCase() == lowerName ||
          category.label.toLowerCase() == lowerName) {
        return category.slug;
      }
    }
    return null;
  }
}
