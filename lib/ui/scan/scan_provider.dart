import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/scan/local_receipt_scanner.dart';
import 'package:mybudget/core/services/scan/label_link_asset.dart';
import 'package:mybudget/core/services/scan/label_span_asset.dart';
import 'package:mybudget/core/services/scan/quick_add_receipt_line_classifier.dart';
import 'package:mybudget/core/services/scan/receipt_line_recognizer.dart';
import 'package:mybudget/core/services/scan/receipt_scan_composer.dart';
import 'package:mybudget/core/services/scan/role_tagger_asset.dart';
import 'package:mybudget/core/services/scan/store_gazetteer_asset.dart';
import 'package:mybudget/core/services/receipt_storage_service.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scan_provider.g.dart';

/// Le flow local, gardé en vie : les modèles de lignes et le moteur de
/// reconnaissance coûtent plus cher à recréer qu'à garder.
@Riverpod(keepAlive: true)
Future<LocalReceiptScanner> localReceiptScanner(Ref ref) async {
  final tagger = RoleTagger(
    LineClassifier.fromJson(
      jsonDecode(
            await rootBundle.loadString(await roleTaggerAssetFromManifest()),
          )
          as Map<String, dynamic>,
    ),
  );
  final link = LabelLinkModel(
    LineClassifier.fromJson(
      jsonDecode(await rootBundle.loadString(await labelLinkAssetFromManifest()))
          as Map<String, dynamic>,
    ),
  );
  final span = LabelSpanModel(
    LineClassifier.fromJson(
      jsonDecode(await rootBundle.loadString(await labelSpanAssetFromManifest()))
          as Map<String, dynamic>,
    ),
  );
  // Le répertoire n'est pas indispensable au flow : s'il manque de la
  // release, on scanne sans, et l'enseigne redevient la ligne désignée.
  Gazetteer? gazetteer;
  try {
    gazetteer = Gazetteer(
      (jsonDecode(
                await rootBundle.loadString(
                  await storeGazetteerAssetFromManifest(),
                ),
              )
              as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as String)),
    );
  } on StateError catch (error) {
    debugPrint('[scan] répertoire d\'enseignes absent : $error');
  }
  final recognizer = MlKitReceiptLineRecognizer();
  ref.onDispose(recognizer.close);
  return LocalReceiptScanner(
    recognizer: recognizer,
    tagger: tagger,
    link: link,
    span: span,
    gazetteer: gazetteer,
  );
}

@Riverpod(keepAlive: true)
Future<ReceiptScanComposer> receiptScanComposer(Ref ref) async {
  final quickAdd = await ref.watch(quickAddClassifierProvider.future);
  return ReceiptScanComposer(
    categorizer: ReceiptCategorizer(QuickAddReceiptLineClassifier(quickAdd)),
    resolver: await ref.watch(categoryDisplayResolverProvider.future),
  );
}

/// La trace de la dernière lecture, pour l'inspecteur de scan.
///
/// Délibérément hors de [ReceiptScanResultModel] : le modèle décrit ce que
/// l'utilisateur valide, la trace explique comment on y est arrivé. Les mêler
/// ferait voyager des détails de pipeline jusque dans la création de dépense.
///
/// Gardée en vie : elle est écrite pendant le scan, alors que personne ne
/// l'écoute — l'inspecteur ne s'ouvre qu'après. Auto-disposée, elle serait
/// détruite dans la foulée et l'écran n'aurait jamais rien à montrer. Ce
/// qu'elle retient est la dernière lecture, remplacée au scan suivant.
@Riverpod(keepAlive: true)
class ScanTrace extends _$ScanTrace {
  @override
  List<ReadTrace> build() => const [];

  void record(List<ReadTrace> trace) => state = trace;
}

@riverpod
class ScanNotifier extends _$ScanNotifier {
  final ReceiptStorageService _storageService = ReceiptStorageService();

  @override
  AsyncValue<ReceiptScanResultModel?> build() {
    return const AsyncData(null);
  }

  /// Le ticket est lu sur l'appareil : la photo ne part nulle part, il n'y a
  /// ni clé, ni quota, ni réseau à gérer.
  Future<void> scanReceipt(Uint8List imageBytes) async {
    state = const AsyncLoading();
    try {
      final watch = Stopwatch()..start();
      final scanner = await ref.read(localReceiptScannerProvider.future);
      final composer = await ref.read(receiptScanComposerProvider.future);
      debugPrint('[scan] chargement des modèles : ${watch.elapsedMilliseconds} ms');
      final read = await scanner.scan(imageBytes);
      ref.read(scanTraceProvider.notifier).record(read.trace);
      final beforeCategories = watch.elapsedMilliseconds;
      state = AsyncData(await composer.compose(read));
      debugPrint(
        '[scan] catégorisation : '
        '${watch.elapsedMilliseconds - beforeCategories} ms, '
        'total ${watch.elapsedMilliseconds} ms',
      );
    } on ScanException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    } catch (error, stackTrace) {
      debugPrint('Scan local impossible : $error\n$stackTrace');
      state = AsyncError(
        const ScanGenericException(message: 'Impossible de lire le ticket'),
        stackTrace,
      );
    }
  }

  void updateItemCategory(int index, String categorySlug, String categoryName) {
    final result = state.value;
    if (result == null) return;
    final updatedItems = [...result.items];
    updatedItems[index] = updatedItems[index].copyWith(
      categorySlug: categorySlug,
      categoryName: categoryName,
    );
    state = AsyncData(result.copyWith(items: updatedItems));
  }

  void updateItemAmount(int index, double amount) {
    final result = state.value;
    if (result == null) return;
    final updatedItems = [...result.items];
    updatedItems[index] = updatedItems[index].copyWith(amount: amount);
    state = AsyncData(result.copyWith(items: updatedItems));
  }

  void updateItemDiscount(int index, double discount) {
    final result = state.value;
    if (result == null) return;
    final updatedItems = [...result.items];
    updatedItems[index] = updatedItems[index].copyWith(discount: discount);
    state = AsyncData(result.copyWith(items: updatedItems));
  }

  void removeItem(int index) {
    final result = state.value;
    if (result == null) return;
    final updatedItems = [...result.items]..removeAt(index);
    state = AsyncData(result.copyWith(items: updatedItems));
  }

  void updateDate(DateTime date) {
    final result = state.value;
    if (result == null) return;
    state = AsyncData(result.copyWith(date: date));
  }

  Future<int> validateAndCreate(int accountId, Uint8List imageBytes) async {
    final result = state.value;
    if (result == null) return 0;

    final receiptPath = await _storageService.saveReceipt(imageBytes);
    final date = result.date ?? DateTime.now();

    final Map<String, List<double>> grouped = {};
    final Map<String, String> categoryLabels = {};

    for (final item in result.items) {
      if (item.categorySlug == null) continue;
      grouped
          .putIfAbsent(item.categorySlug!, () => [])
          .add(item.effectiveAmount);
      categoryLabels.putIfAbsent(
        item.categorySlug!,
        () => item.categoryName ?? '',
      );
    }

    int count = 0;
    final expenseNotifier = ref.read(expenseProvider.notifier);
    final storeName = result.storeName;

    for (final entry in grouped.entries) {
      final totalAmount = entry.value.fold(0.0, (sum, a) => sum + a);
      final label = categoryLabels[entry.key] ?? '';
      final name = storeName != null
          ? '$storeName — $label'
          : 'Ticket du ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} — $label';

      final expense = ExpenseModel.create(
        name: name,
        amount: totalAmount,
        categorySlug: entry.key,
        startDate: date,
        frequency: Frequency.oneTime.label,
        accountId: accountId,
        receiptPath: receiptPath,
      );

      await expenseNotifier.addExpense(expense);
      count++;
    }

    return count;
  }

  void reset() {
    state = const AsyncData(null);
  }
}
