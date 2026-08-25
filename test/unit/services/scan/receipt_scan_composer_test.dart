import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/scan/local_receipt_scanner.dart';
import 'package:mybudget/core/services/scan/receipt_scan_composer.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

/// Rend la prédiction inscrite pour un libellé, `divers.autre` sinon.
class _ScriptedLineClassifier implements ReceiptLineClassifier {
  _ScriptedLineClassifier(this.predictions);

  final Map<String, LinePrediction> predictions;
  final List<String> seen = [];

  @override
  Future<LinePrediction> classify(String normalizedLine) async {
    seen.add(normalizedLine);
    return predictions[normalizedLine] ?? (slug: 'divers.autre', confidence: 0.1);
  }
}

LocalReceiptScan scanOf({
  String? store = 'CARREFOUR',
  String? date = '2026-08-01',
  FlowStage stage = FlowStage.local,
  List<(String, double, double)> items = const [('PAIN', 2.0, 0.0)],
}) {
  return LocalReceiptScan(
    stage: stage,
    store: store,
    date: date,
    total: 2.0,
    items: [
      for (final (name, amount, discount) in items)
        ExtractedItem(name: name, amount: amount, discount: discount),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CategoryDisplayResolver resolver;

  setUpAll(() async {
    final taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
    resolver = CategoryDisplayResolver(taxonomy: taxonomy, overrides: const {});
  });

  ReceiptScanComposer composerOf(Map<String, LinePrediction> predictions) {
    return ReceiptScanComposer(
      categorizer: ReceiptCategorizer(_ScriptedLineClassifier(predictions)),
      resolver: resolver,
    );
  }

  group('ReceiptScanComposer', () {
    test('la catégorie de l\'enseigne couvre les articles', () async {
      final result = await composerOf({
        'carrefour': (slug: 'alimentation.supermarche', confidence: 0.99),
      }).compose(scanOf(items: const [('PAIN', 2.0, 0.0), ('LAIT', 3.0, 0.0)]));

      expect(
        [for (final item in result.items) item.categorySlug],
        ['alimentation.supermarche', 'alimentation.supermarche'],
      );
      expect(result.items.first.categoryName, isNotEmpty);
    });

    test('un article d\'une autre famille sort de la classe du ticket',
        () async {
      final result = await composerOf({
        'carrefour': (slug: 'alimentation.supermarche', confidence: 0.99),
        'croquettes chien': (slug: 'divers.animaux', confidence: 0.95),
      }).compose(
        scanOf(items: const [('PAIN', 2.0, 0.0), ('CROQUETTES CHIEN', 9.0, 0.0)]),
      );

      expect(result.items[0].categorySlug, 'alimentation.supermarche');
      expect(result.items[1].categorySlug, 'divers.animaux');
    });

    test('les libellés sont normalisés avant le modèle', () async {
      final classifier = _ScriptedLineClassifier({});
      await ReceiptScanComposer(
        categorizer: ReceiptCategorizer(classifier),
        resolver: resolver,
      ).compose(scanOf(store: null, items: const [('*PAIN 4X125G', 2.0, 0.0)]));

      expect(classifier.seen, ['pain']);
    });

    test('une catégorie inconnue de la taxonomie n\'est pas inventée',
        () async {
      final result = await composerOf({
        'carrefour': (slug: 'categorie.disparue', confidence: 0.99),
      }).compose(scanOf());

      expect(result.items.single.categorySlug, isNull);
      expect(result.items.single.categoryName, isNull);
    });

    test('la date lue est rendue en DateTime', () async {
      final result = await composerOf(const {}).compose(scanOf());

      expect(result.date, DateTime(2026, 8, 1));
      expect(result.storeName, 'CARREFOUR');
    });

    test('un ticket non vérifié le reste jusqu\'à l\'écran', () async {
      final verified = await composerOf(const {}).compose(scanOf());
      final flagged = await composerOf(
        const {},
      ).compose(scanOf(stage: FlowStage.confirm));

      expect(verified.verified, isTrue);
      expect(flagged.verified, isFalse);
    });

    test('la remise lue est conservée', () async {
      final result = await composerOf(
        const {},
      ).compose(scanOf(items: const [('PAIN', 2.0, 0.5)]));

      expect(result.items.single.discount, 0.5);
      expect(result.items.single.effectiveAmount, 1.5);
    });
  });
}
