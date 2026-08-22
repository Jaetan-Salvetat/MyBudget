import 'package:mybudget/core/constants/quick_add_labels.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/quick_add/price_parser_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';
import 'package:mybudget/core/services/quick_add/quick_add_model_runner.dart';
import 'package:mybudget/core/services/quick_add/quick_add_tokenizer.dart';

class QuickAddClassifierService {
  static const String _recurringLabel = 'fixe';

  final QuickAddTokenizer _tokenizer;
  final QuickAddModelRunner _modelRunner;
  final CategoryTaxonomyService _taxonomy;

  QuickAddClassifierService({
    required QuickAddTokenizer tokenizer,
    required QuickAddModelRunner modelRunner,
    required CategoryTaxonomyService taxonomy,
  }) : _tokenizer = tokenizer,
       _modelRunner = modelRunner,
       _taxonomy = taxonomy;

  Future<void> load() async {
    await _tokenizer.load();
    await _taxonomy.load();
    await _modelRunner.load();
  }

  /// Reads everything the text carries. The amount stays null while the user
  /// has not typed one : classifying is understanding, not validating.
  Future<QuickAddClassification> classify(String input) async {
    final priceResult = PriceParserService.parse(input);

    final cleanedText = priceResult == null || priceResult.remaining.isEmpty
        ? input
        : priceResult.remaining;

    final tokens = _tokenizer.encode(cleanedText);
    final output = await _modelRunner.run(tokens);

    final slug = QuickAddLabels.categories[output.category.index];
    final category = _taxonomy.resolve(slug);
    if (category == null) {
      throw QuickAddClassificationException(
        message: 'Catégorie inconnue : $slug',
      );
    }

    final type = TransactionType.values[output.type.index];
    final recurrence = QuickAddLabels.recurrences[output.recurrence.index];
    final frequency = recurrence == _recurringLabel
        ? Frequency.monthly
        : Frequency.oneTime;

    return QuickAddClassification(
      type: type,
      category: category,
      frequency: frequency,
      amount: priceResult?.price,
      name: _buildName(priceResult?.remaining ?? input, category),
      typeConfidence: output.type.confidence,
      categoryConfidence: output.category.confidence,
      recurrenceConfidence: output.recurrence.confidence,
      categorySuggestions: _suggestionsFor(output.category.topIndices),
      cleanedText: cleanedText,
    );
  }

  List<String> _suggestionsFor(List<int> indices) {
    return indices
        .map((index) => QuickAddLabels.categories[index])
        .where((slug) => _taxonomy.resolve(slug) != null)
        .toList();
  }

  String _buildName(String cleanedText, TaxonomyNode category) {
    final trimmed = cleanedText.trim();
    if (trimmed.isEmpty) return category.label;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}
