import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/data/provider/ai_settings_provider.dart';
import 'package:mybudget/data/provider/category_override_provider.dart';
import 'package:mybudget/data/provider/gemini_nano_provider.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/service/ai/ai_chat_client.dart';
import 'package:mybudget/data/service/scan/cloud_receipt_reader.dart';
import 'package:mybudget/data/service/scan/label_link_asset.dart';
import 'package:mybudget/data/service/scan/label_span_asset.dart';
import 'package:mybudget/data/service/scan/local_receipt_scanner.dart';
import 'package:mybudget/data/service/scan/nano_receipt_reader.dart';
import 'package:mybudget/data/service/scan/quick_add_receipt_line_classifier.dart';
import 'package:mybudget/data/service/scan/receipt_line_recognizer.dart';
import 'package:mybudget/data/service/scan/receipt_scan_composer.dart';
import 'package:mybudget/data/service/scan/role_tagger_asset.dart';
import 'package:mybudget/data/service/scan/store_classifier_asset.dart';
import 'package:mybudget/data/service/scan/store_gazetteer_asset.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'receipt_reader_provider.g.dart';

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
  StoreClassifier? classifier;
  try {
    classifier = StoreClassifier.fromJson(
      jsonDecode(
            await rootBundle.loadString(
              await storeClassifierAssetFromManifest(),
            ),
          )
          as Map<String, dynamic>,
    );
  } on StateError catch (error) {
    debugPrint("[scan] classifieur d'enseigne absent : $error");
  }
  final recognizer = MlKitReceiptLineRecognizer();
  ref.onDispose(recognizer.close);
  return LocalReceiptScanner(
    recognizer: recognizer,
    tagger: tagger,
    link: link,
    span: span,
    gazetteer: gazetteer,
    classifier: classifier,
  );
}

@Riverpod(keepAlive: true)
Future<ReceiptScanComposer> receiptScanComposer(Ref ref) async {
  final quickAdd = await ref.watch(quickAddClassifierProvider.future);
  return ReceiptScanComposer(
    categorizer: ReceiptCategorizer(QuickAddReceiptLineClassifier(quickAdd)),
    resolver: await ref.watch(categoryDisplayResolverProvider.future),
    clock: ref.watch(clockProvider),
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
