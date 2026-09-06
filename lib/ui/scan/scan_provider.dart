
import 'package:flutter/foundation.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';
import 'package:mybudget/core/formatting/date_formatter.dart';
import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/model/receipt_scan_result_model.dart';
import 'package:mybudget/data/model/scan_read_progress_model.dart';
import 'package:mybudget/data/model/scanned_item_model.dart';
import 'package:mybudget/data/provider/expenses_provider.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/provider/receipt_reader_provider.dart';
import 'package:mybudget/data/service/receipt_storage_service.dart';
import 'package:mybudget/data/service/scan/local_receipt_scan.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scan_provider.g.dart';

@Riverpod(keepAlive: true)
class ScanTrace extends _$ScanTrace {
  @override
  List<ReadTrace> build() => const [];

  void record(List<ReadTrace> trace) => state = trace;
}

@riverpod
class ScanProgress extends _$ScanProgress {
  @override
  ScanReadProgress build() => const ScanReadProgress();

  void report(ReceiptReadPart part) {
    final date = part.date;
    state = state.copyWith(
      storeName: part.store,
      printedTotal: part.total,
      date: date == null ? null : DateTime.tryParse(date),
    );
  }

  void clear() => state = const ScanReadProgress();
}

@riverpod
class ScanNotifier extends _$ScanNotifier {
  ReceiptStorageService get _storageService =>
      ReceiptStorageService(ref.read(clockProvider));

  @override
  AsyncValue<ReceiptScanResultModel?> build() {
    return const AsyncData(null);
  }

  Future<void> scanReceipt(Uint8List imageBytes) async {
    state = const AsyncLoading();
    ref.read(scanProgressProvider.notifier).clear();
    try {
      final watch = Stopwatch()..start();
      final read = await _read(imageBytes);
      final composer = await ref.read(receiptScanComposerProvider.future);
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

  Future<LocalReceiptScan> _read(Uint8List imageBytes) async {
    final cloud = await ref.read(cloudReceiptReaderProvider.future);
    if (cloud != null) return cloud.read(imageBytes);

    final scanner = await ref.read(localReceiptScannerProvider.future);
    return scanner.scan(
      imageBytes,
      nano: ref.read(nanoReceiptReaderProvider),
      onPart: ref.read(scanProgressProvider.notifier).report,
    );
  }

  void updateItemCategory(int index, String categorySlug, String categoryName) {
    _replaceItem(
      index,
      (item) => item.copyWith(
        categorySlug: categorySlug,
        categoryName: categoryName,
        confirmedByUser: true,
      ),
    );
  }

  void updateItemName(int index, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _replaceItem(index, (item) => item.copyWith(name: trimmed));
  }

  void updateStoreName(String storeName) {
    final result = state.value;
    if (result == null) return;
    final trimmed = storeName.trim();
    if (trimmed.isEmpty) return;
    state = AsyncData(result.copyWith(storeName: trimmed));
  }

  void addItem(ScannedItemModel item) {
    final result = state.value;
    if (result == null) return;
    state = AsyncData(result.copyWith(items: [...result.items, item]));
  }

  void insertItem(int index, ScannedItemModel item) {
    final result = state.value;
    if (result == null) return;
    final updatedItems = [...result.items]..insert(index, item);
    state = AsyncData(result.copyWith(items: updatedItems));
  }

  void _replaceItem(
    int index,
    ScannedItemModel Function(ScannedItemModel item) update,
  ) {
    final result = state.value;
    if (result == null) return;
    if (index < 0 || index >= result.items.length) return;
    final updatedItems = [...result.items];
    updatedItems[index] = update(updatedItems[index]);
    state = AsyncData(result.copyWith(items: updatedItems));
  }

  void updateItemAmount(int index, double amount) {
    _replaceItem(index, (item) => item.copyWith(amount: amount));
  }

  void updateItemDiscount(int index, double discount) {
    _replaceItem(index, (item) => item.copyWith(discount: discount));
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

  Future<List<int>> validateAndCreate(
    int accountId,
    Uint8List imageBytes,
  ) async {
    final result = state.value;
    if (result == null) return const [];

    final receiptPath = await _storageService.saveReceipt(imageBytes);
    final date = result.date;

    final created = <int>[];
    final expenseNotifier = ref.read(expenseProvider.notifier);
    final storeName = result.storeName;

    for (final group in result.groupedByCategory) {
      final name = storeName != null
          ? '$storeName — ${group.label}'
          : 'Ticket du ${DateFormatter.longDate.format(date)} — ${group.label}';

      created.add(
        await expenseNotifier.addExpense(
          ExpenseModel.create(
            name: name,
            amount: group.total,
            categorySlug: group.slug,
            startDate: date,
            frequency: Frequency.oneTime,
            accountId: accountId,
            receiptPath: receiptPath,
          ),
        ),
      );
    }

    return created;
  }

  Future<void> discardCreated(List<int> ids) async {
    final expenseNotifier = ref.read(expenseProvider.notifier);
    for (final id in ids) {
      await expenseNotifier.deleteExpense(id);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}
