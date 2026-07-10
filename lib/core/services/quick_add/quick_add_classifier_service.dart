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
  })  : _tokenizer = tokenizer,
        _modelRunner = modelRunner,
        _taxonomy = taxonomy;

  Future<void> load() async {
    await _tokenizer.load();
    await _taxonomy.load();
    await _modelRunner.load();
  }

  Future<QuickAddClassification> classify(String input) async {
    final priceResult = PriceParserService.parse(input);
    if (priceResult == null) {
      throw const QuickAddNoAmountException();
    }

    final cleanedText =
        priceResult.remaining.isEmpty ? input : priceResult.remaining;

    final tokens = _tokenizer.encode(cleanedText);
    final output = await _modelRunner.run(tokens);

    final taxonomyCategory = QuickAddLabels.categories[output.category.index];
    final group = _taxonomy.resolve(taxonomyCategory);
    if (group == null) {
      throw QuickAddClassificationException(
        message: 'Catégorie inconnue : $taxonomyCategory',
      );
    }

    final type = TransactionType.values[output.type.index];
    final recurrence = QuickAddLabels.recurrences[output.recurrence.index];
    final frequency = recurrence == _recurringLabel
        ? Frequency.monthly
        : Frequency.oneTime;

    return QuickAddClassification(
      type: type,
      group: group,
      taxonomyCategory: taxonomyCategory,
      frequency: frequency,
      amount: priceResult.price,
      name: _buildName(priceResult.remaining, group),
      typeConfidence: output.type.confidence,
      categoryConfidence: output.category.confidence,
      recurrenceConfidence: output.recurrence.confidence,
    );
  }

  String _buildName(String cleanedText, TaxonomyGroup group) {
    final trimmed = cleanedText.trim();
    if (trimmed.isEmpty) return group.label;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}
