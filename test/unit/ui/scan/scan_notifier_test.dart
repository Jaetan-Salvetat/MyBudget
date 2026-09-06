import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/data/model/receipt_scan_result_model.dart';
import 'package:mybudget/data/model/scanned_item_model.dart';
import 'package:mybudget/ui/scan/scan_provider.dart';

class _SeededScan extends ScanNotifier {
  _SeededScan(this._seed);

  final ReceiptScanResultModel _seed;

  @override
  AsyncValue<ReceiptScanResultModel?> build() => AsyncData(_seed);
}

ScannedItemModel itemOf({
  String name = 'Pain complet',
  double amount = 2.0,
  String? slug = 'alimentation.boulangerie',
  double confidence = 0.9,
}) {
  return ScannedItemModel(
    name: name,
    amount: amount,
    categorySlug: slug,
    categoryName: slug == null ? null : 'Boulangerie',
    categoryConfidence: confidence,
  );
}

final DateTime _fixedNow = DateTime(2026, 6, 15, 9, 30);

void main() {
  late ProviderContainer container;

  ReceiptScanResultModel seedOf(List<ScannedItemModel> items) {
    return ReceiptScanResultModel(
      date: _fixedNow,
      storeName: 'Carrefour',
      printedTotal: 10.0,
      items: items,
    );
  }

  void seed(List<ScannedItemModel> items) {
    container = ProviderContainer(
      overrides: [scanProvider.overrideWith(() => _SeededScan(seedOf(items)))],
    );
    addTearDown(container.dispose);
  }

  ReceiptScanResultModel read() => container.read(scanProvider).value!;
  ScanNotifier notifier() => container.read(scanProvider.notifier);

  group('ScanNotifier', () {
    test('ranger un article le marque comme confirmé par l\'utilisateur', () {
      seed([itemOf(confidence: 0.2)]);

      notifier().updateItemCategory(0, 'maison.entretien', 'Entretien');

      final item = read().items.single;
      expect(item.categorySlug, 'maison.entretien');
      expect(item.categoryName, 'Entretien');
      expect(item.confirmedByUser, isTrue);
      expect(item.isCategoryUncertain, isFalse);
      expect(item.needsAttention, isFalse);
    });

    test('un article ajouté se pose en fin de liste', () {
      seed([itemOf()]);

      notifier().addItem(itemOf(name: 'Sacs cabas', amount: 1.75, slug: null));

      expect(read().items.length, 2);
      expect(read().items.last.name, 'Sacs cabas');
      expect(read().itemsTotal, closeTo(3.75, 0.001));
    });

    test('un article retiré peut être remis à sa place', () {
      seed([itemOf(name: 'Un'), itemOf(name: 'Deux'), itemOf(name: 'Trois')]);
      final removed = read().items[1];

      notifier().removeItem(1);
      expect(read().items.map((item) => item.name), ['Un', 'Trois']);

      notifier().insertItem(1, removed);
      expect(read().items.map((item) => item.name), ['Un', 'Deux', 'Trois']);
    });

    test('un montant corrigé conserve la remise lue', () {
      seed([
        ScannedItemModel(
          name: 'Lessive',
          amount: 8.90,
          discount: 1.50,
          categorySlug: 'maison.entretien',
          categoryName: 'Entretien',
          categoryConfidence: 0.9,
        ),
      ]);

      notifier().updateItemAmount(0, 9.50);

      expect(read().items.single.amount, 9.50);
      expect(read().items.single.discount, 1.50);
      expect(read().items.single.effectiveAmount, 8.0);
    });

    test('le nom corrigé remplace celui du modèle', () {
      seed([itemOf()]);

      notifier().updateItemName(0, 'Pain de campagne');

      expect(read().items.single.name, 'Pain de campagne');
    });

    test('un nom vide ne remplace rien', () {
      seed([itemOf()]);

      notifier().updateItemName(0, '   ');

      expect(read().items.single.name, 'Pain complet');
    });

    test('l\'enseigne corrigée remplace celle du modèle', () {
      seed([itemOf()]);

      notifier().updateStoreName('Carrefour Market');

      expect(read().storeName, 'Carrefour Market');
    });
  });
}
