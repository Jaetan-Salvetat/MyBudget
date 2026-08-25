import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/scan/local_receipt_scanner.dart';
import 'package:mybudget/core/services/scan/quick_add_receipt_line_classifier.dart';
import 'package:mybudget/core/services/scan/receipt_line_recognizer.dart';
import 'package:mybudget/core/services/scan/receipt_scan_composer.dart';
import 'package:mybudget/core/services/receipt_storage_service.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scan_provider.g.dart';

/// Le classifieur de lignes exporté depuis la recherche
/// (`ml/scan/research/line_classifier/export.py`), embarqué avec l'app.
const String lineClassifierAsset = 'assets/models/line_clf_v3.json';

/// Le flow local, gardé en vie : le classifieur de lignes et le moteur de
/// reconnaissance coûtent plus cher à recréer qu'à garder.
@Riverpod(keepAlive: true)
Future<LocalReceiptScanner> localReceiptScanner(Ref ref) async {
  final json = await rootBundle.loadString(lineClassifierAsset);
  final classifier = LineClassifier.fromJson(
    jsonDecode(json) as Map<String, dynamic>,
  );
  final recognizer = MlKitReceiptLineRecognizer();
  ref.onDispose(recognizer.close);
  return LocalReceiptScanner(recognizer: recognizer, classifier: classifier);
}

@Riverpod(keepAlive: true)
Future<ReceiptScanComposer> receiptScanComposer(Ref ref) async {
  final quickAdd = await ref.watch(quickAddClassifierProvider.future);
  return ReceiptScanComposer(
    categorizer: ReceiptCategorizer(QuickAddReceiptLineClassifier(quickAdd)),
    resolver: await ref.watch(categoryDisplayResolverProvider.future),
  );
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
      final scanner = await ref.read(localReceiptScannerProvider.future);
      final composer = await ref.read(receiptScanComposerProvider.future);
      state = AsyncData(await composer.compose(await scanner.scan(imageBytes)));
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
