import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/core/services/scan/cloud_receipt_reader.dart';
import 'package:mybudget/core/services/scan/local_receipt_scan.dart';
import 'package:mybudget/core/services/scan/local_receipt_scanner.dart';
import 'package:mybudget/core/services/scan/nano_receipt_reader.dart';
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
import 'package:mybudget/models/scan_read_progress_model.dart';
import 'package:mybudget/models/scanned_item_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/scan/scan_formats.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:mybudget/ui/settings/gemini_nano_provider.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scan_provider.g.dart';

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
      jsonDecode(
            await rootBundle.loadString(await labelLinkAssetFromManifest()),
          )
          as Map<String, dynamic>,
    ),
  );
  final span = LabelSpanModel(
    LineClassifier.fromJson(
      jsonDecode(
            await rootBundle.loadString(await labelSpanAssetFromManifest()),
          )
          as Map<String, dynamic>,
    ),
  );
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

@Riverpod(keepAlive: true)
NanoReceiptReader? nanoReceiptReader(Ref ref) {
  if (ref.watch(quickAddEngineModeProvider) != QuickAddEngineMode.onDevice) {
    return null;
  }
  if (!ref.watch(geminiNanoScanProvider)) return null;
  if (ref.watch(geminiNanoStatusProvider).value?.isReady != true) return null;

  return NanoReceiptReader(service: ref.watch(geminiNanoServiceProvider));
}

@Riverpod(keepAlive: true)
bool cloudScanSelected(Ref ref) {
  if (ref.watch(quickAddEngineModeProvider) != QuickAddEngineMode.apiKey) {
    return false;
  }
  return ref.watch(hasStoredApiKeyProvider).value ?? false;
}

@Riverpod(keepAlive: true)
Future<CloudReceiptReader?> cloudReceiptReader(Ref ref) async {
  if (!ref.watch(cloudScanSelectedProvider)) return null;

  final provider = ref.watch(selectedAiProviderProvider);
  final String? apiKey;
  try {
    apiKey = await ref.watch(apiKeyServiceProvider).read(provider);
  } catch (error, stackTrace) {
    debugPrint('[scan] lecture de la clé API impossible : $error\n$stackTrace');
    return null;
  }
  if (apiKey == null) return null;

  final client = OpenAiCompatibleChatClient(
    provider: provider,
    model: ref.watch(selectedAiModelProvider),
    apiKey: apiKey,
  );
  ref.onDispose(client.close);

  return CloudReceiptReader(client: client);
}

@Riverpod(keepAlive: true)
bool receiptScanAvailable(Ref ref) =>
    ref.watch(nanoReceiptReaderProvider) != null ||
    ref.watch(cloudScanSelectedProvider);

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
  final ReceiptStorageService _storageService = ReceiptStorageService();

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

    final nano = ref.read(nanoReceiptReaderProvider);
    if (nano == null) throw const ScanUnavailableException();

    final scanner = await ref.read(localReceiptScannerProvider.future);
    return scanner.scan(
      imageBytes,
      nano: nano,
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
          : 'Ticket du ${scanDate.format(date)} — ${group.label}';

      created.add(
        await expenseNotifier.addExpense(
          ExpenseModel.create(
            name: name,
            amount: group.total,
            categorySlug: group.slug,
            startDate: date,
            frequency: Frequency.oneTime.label,
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
