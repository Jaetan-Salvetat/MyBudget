import 'package:flutter/foundation.dart';

import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/services/receipt_scan_service.dart';
import 'package:mybudget/core/services/receipt_storage_service.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scan_provider.g.dart';

/// Le service de scan, ou rien quand aucune clé ne peut le servir. Il partage
/// le fournisseur, le modèle et la clé de l'ajout rapide. Gardé en vie le
/// temps d'un scan : le client HTTP se fermerait sous la requête en cours.
@Riverpod(keepAlive: true)
Future<ReceiptScanService?> receiptScanService(Ref ref) async {
  if (ref.watch(quickAddEngineModeProvider) != QuickAddEngineMode.apiKey) {
    return null;
  }

  final provider = ref.watch(selectedAiProviderProvider);

  final String? apiKey;
  try {
    apiKey = await ref.watch(apiKeyServiceProvider).read(provider);
  } catch (error, stackTrace) {
    debugPrint('Lecture de la clé API impossible : $error\n$stackTrace');
    return null;
  }
  if (apiKey == null) return null;

  final client = OpenAiCompatibleChatClient(
    provider: provider,
    model: ref.watch(selectedAiModelProvider),
    apiKey: apiKey,
  );
  ref.onDispose(client.close);

  return ReceiptScanService(client: client);
}

@riverpod
class ScanNotifier extends _$ScanNotifier {
  final ReceiptStorageService _storageService = ReceiptStorageService();

  @override
  AsyncValue<ReceiptScanResultModel?> build() {
    return const AsyncData(null);
  }

  Future<void> scanReceipt(AiImageAttachment image) async {
    state = const AsyncLoading();
    try {
      final lastTimestamp = PreferencesService.getLastScanTimestamp();
      final elapsed =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 - lastTimestamp;
      final remaining = ScanException.scanCooldownSeconds - elapsed;
      if (remaining > 0) {
        throw ScanCooldownException(retryAfterSeconds: remaining);
      }

      final scanService = await ref.read(receiptScanServiceProvider.future);
      if (scanService == null) throw const ScanMissingApiKeyException();

      final resolver = await ref.read(categoryDisplayResolverProvider.future);
      final categories = resolver
          .groupsOfType(TransactionType.expense)
          .expand((group) => resolver.childrenOf(group.slug))
          .toList();
      final result = await scanService.extractItems(image, categories);
      await PreferencesService.setLastScanTimestamp(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      await ref.read(quickAddDegradationProvider.notifier).reportSuccess();
      state = AsyncData(result);
    } on ScanException catch (e, st) {
      state = AsyncError(e, st);
    } catch (e, st) {
      // La clé est la même que celle de l'ajout rapide : un refus constaté
      // ici doit compter dans sa santé, sinon l'ajout rapide continuera de
      // tenter le distant avec une clé qu'on sait morte.
      final failure = AiRequestFailure.from(e);
      await ref
          .read(quickAddDegradationProvider.notifier)
          .reportFailure(failure);
      state = AsyncError(ScanException.fromFailure(failure), st);
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
