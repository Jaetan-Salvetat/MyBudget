import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/data/service/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/data/service/quick_add/quick_add_classification.dart';
import 'package:mybudget/data/service/quick_add/quick_add_engine.dart';
import 'package:mybudget/data/service/quick_add/quick_add_text_reader.dart';

class ScriptedClassification {
  const ScriptedClassification({
    required this.categorySlug,
    required this.name,
    this.type = TransactionType.expense,
    this.frequency = Frequency.oneTime,
    this.amount,
    this.date,
    this.categoryConfidence = 0.95,
    this.categorySuggestions = const <String>[],
  });

  final String categorySlug;
  final String name;
  final TransactionType type;
  final Frequency frequency;
  final double? amount;
  final DateTime? date;
  final double categoryConfidence;
  final List<String> categorySuggestions;
}

class FakeQuickAddEngine implements QuickAddEngine {
  FakeQuickAddEngine({
    required this._taxonomy,
    required this._now,
    Map<String, ScriptedClassification> script =
        const <String, ScriptedClassification>{},
  }) : _script = Map<String, ScriptedClassification>.of(script);

  final CategoryTaxonomyService _taxonomy;
  final DateTime _now;
  final Map<String, ScriptedClassification> _script;

  final List<String> seenInputs = <String>[];

  Object? _failure;

  void script(String input, ScriptedClassification classification) {
    _script[input] = classification;
  }

  void failWith(Object error) => _failure = error;

  @override
  Future<QuickAddClassification> classify(String input) async {
    seenInputs.add(input);

    final Object? error = _failure;
    if (error != null) throw error;

    final ScriptedClassification? scripted = _script[input];
    if (scripted == null) {
      throw QuickAddClassificationException(
        message: 'Aucune classification scriptée pour « $input »',
      );
    }

    final TaxonomyNode? node = _taxonomy.resolve(scripted.categorySlug);
    if (node == null) {
      throw QuickAddClassificationException(
        message: 'Slug inconnu de la taxonomie : ${scripted.categorySlug}',
      );
    }

    final QuickAddTextFacts facts = QuickAddTextReader.read(input, today: _now);

    return QuickAddClassification(
      type: scripted.type,
      category: node,
      frequency: scripted.frequency,
      date: scripted.date ?? facts.date,
      hasWrittenDate: facts.hasWrittenDate,
      amount: scripted.amount ?? facts.amount,
      name: scripted.name,
      typeConfidence: 0.95,
      categoryConfidence: scripted.categoryConfidence,
      recurrenceConfidence: 0.95,
      cleanedText: facts.modelText,
      categorySuggestions: scripted.categorySuggestions,
    );
  }
}
