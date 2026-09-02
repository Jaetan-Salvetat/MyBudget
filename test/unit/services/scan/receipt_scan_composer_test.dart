import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/scan/local_receipt_scan.dart';
import 'package:mybudget/core/services/scan/receipt_scan_composer.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

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
  bool verified = true,
  double? total = 2.0,
  List<(String, double, double)> items = const [('PAIN', 2.0, 0.0)],
}) {
  return LocalReceiptScan(
    verified: verified,
    store: store,
    date: date,
    total: total,
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
    test('chaque article porte la catégorie de son propre libellé', () async {
      final result = await composerOf({
        'pain': (slug: 'alimentation.boulangerie', confidence: 0.9),
        'croquettes chien': (slug: 'divers.animaux', confidence: 0.95),
      }).compose(
        scanOf(items: const [('PAIN', 2.0, 0.0), ('CROQUETTES CHIEN', 9.0, 0.0)]),
      );

      expect(result.items[0].categorySlug, 'alimentation.boulangerie');
      expect(result.items[1].categorySlug, 'divers.animaux');
      expect(result.items.first.categoryName, isNotEmpty);
    });

    test('l\'enseigne ne teinte pas la catégorie des articles', () async {
      final classifier = _ScriptedLineClassifier({
        'pain': (slug: 'alimentation.boulangerie', confidence: 0.9),
      });
      final result = await ReceiptScanComposer(
        categorizer: ReceiptCategorizer(classifier),
        resolver: resolver,
      ).compose(scanOf(store: 'CARREFOUR'));

      expect(result.items.single.categorySlug, 'alimentation.boulangerie');
      expect(classifier.seen, ['pain']);
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
        'pain': (slug: 'categorie.disparue', confidence: 0.99),
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
      ).compose(scanOf(verified: false));

      expect(verified.verified, isTrue);
      expect(flagged.verified, isFalse);
    });

    test('le total imprimé arrive jusqu\'à l\'écran', () async {
      final read = await composerOf(const {}).compose(scanOf(total: 3.75));
      final blind = await composerOf(const {}).compose(scanOf(total: null));

      expect(read.printedTotal, 3.75);
      expect(read.gap, 1.75);
      expect(blind.printedTotal, isNull);
      expect(blind.hasGap, isFalse);
    });

    test('la confiance du classifieur arrive jusqu\'à l\'écran', () async {
      final result = await composerOf({
        'pain': (slug: 'alimentation.boulangerie', confidence: 0.31),
      }).compose(scanOf());

      expect(result.items.single.categoryConfidence, 0.31);
      expect(result.items.single.isCategoryUncertain, isTrue);
    });

    test('une catégorie inconnue ne garde pas la confiance du modèle',
        () async {
      final result = await composerOf({
        'pain': (slug: 'categorie.disparue', confidence: 0.99),
      }).compose(scanOf());

      expect(result.items.single.categoryConfidence, 0);
      expect(result.items.single.needsAttention, isTrue);
    });

    test('les libellés affichés ne crient plus', () async {
      final result = await composerOf(const {}).compose(
        scanOf(items: const [('LAIT ECREME 6X1L', 6.54, 0.0)]),
      );

      expect(result.items.single.name, 'Lait ecreme 6X1L');
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
