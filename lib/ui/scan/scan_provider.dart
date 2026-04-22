import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/services/receipt_scan_service.dart';
import 'package:mybudget/core/services/receipt_storage_service.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/settings/category_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scan_provider.g.dart';

@riverpod
class ScanNotifier extends _$ScanNotifier {
  final ReceiptScanService _scanService = ReceiptScanService();
  final ReceiptStorageService _storageService = ReceiptStorageService();

  @override
  AsyncValue<ReceiptScanResultModel?> build() {
    return const AsyncData(null);
  }

  Future<void> scanReceipt(Uint8List imageBytes) async {
    state = const AsyncLoading();
    try {
      final lastTimestamp = PreferencesService.getLastScanTimestamp();
      final elapsed = DateTime.now().millisecondsSinceEpoch ~/ 1000 - lastTimestamp;
      final remaining = ScanException.scanCooldownSeconds - elapsed;
      if (remaining > 0) {
        throw ScanCooldownException(retryAfterSeconds: remaining);
      }

      final categories = ref.read(categoryProvider).value ?? [];
      final result = await _scanService.extractItems(imageBytes, categories);
      await PreferencesService.setLastScanTimestamp(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      state = AsyncData(result);
    } on ScanException catch (e, st) {
      state = AsyncError(e, st);
    } on ServerException catch (e, st) {
      final message = e.message.toUpperCase();
      if (message.contains('429') || message.contains('RESOURCE_EXHAUSTED')) {
        await PreferencesService.setLastScanTimestamp(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );
        state = AsyncError(const ScanRateLimitException(), st);
      } else {
        state = AsyncError(ScanGenericException(details: e.message), st);
      }
    } catch (e, st) {
      state = AsyncError(ScanGenericException(details: e.toString()), st);
    }
  }

  void updateItemCategory(int index, int categoryId, String categoryName) {
    final result = state.value;
    if (result == null) return;
    final updatedItems = [...result.items];
    updatedItems[index] = updatedItems[index].copyWith(
      categoryId: categoryId,
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

    final Map<int, List<double>> grouped = {};
    final Map<int, String> categoryLabels = {};

    for (final item in result.items) {
      if (item.categoryId == null) continue;
      grouped.putIfAbsent(item.categoryId!, () => []).add(item.amount);
      categoryLabels.putIfAbsent(item.categoryId!, () => item.categoryName ?? '');
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
        categoryId: entry.key,
        startDate: date,
        frequency: Frequency.oneTime.label,
        accountId: accountId,
        receiptPath: receiptPath,
      );

      try {
        await expenseNotifier.addExpense(expense);
        count++;
      } catch (e) {
        rethrow;
      }
    }

    return count;
  }

  void reset() {
    state = const AsyncData(null);
  }
}
