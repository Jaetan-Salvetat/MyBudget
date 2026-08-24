import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

import 'ocr_dump.dart';
import 'preprocess.dart';

class OcrPass {
  const OcrPass({
    required this.recognized,
    required this.receipt,
    required this.latencyMs,
    required this.imageWidth,
    required this.imageHeight,
  });

  final RecognizedText recognized;
  final ExtractedReceipt receipt;
  final int latencyMs;
  final int imageWidth;
  final int imageHeight;
}

class LocalScanResult {
  const LocalScanResult({
    required this.outcome,
    required this.pass1,
    required this.retry,
  });

  final FlowOutcome outcome;
  final OcrPass pass1;
  final OcrPass? retry;

  bool get retryUsed => retry != null;

  int get totalLatencyMs => pass1.latencyMs + (retry?.latencyMs ?? 0);
}

/// Le flow local complet sur une image : OCR + structuration, puis retry
/// prétraité si le checksum échoue. Un stage `confirm` = échec détecté :
/// dans l'app, écran de confirmation pré-rempli.
Future<LocalScanResult> runLocalFlow(
  TextRecognizer recognizer,
  File imageFile,
  Directory tempDir,
) async {
  final pass1 = await _runPass(recognizer, imageFile);

  OcrPass? retry;
  if (!pass1.receipt.checksumOk) {
    retry = await _runRetry(recognizer, imageFile, tempDir);
  }

  final outcome = decide(
    pass1.receipt,
    retry?.receipt,
    null,
    FlowPolicy.recommended,
  );
  return LocalScanResult(outcome: outcome, pass1: pass1, retry: retry);
}

/// Un retry qui échoue techniquement (image indéchiffrable, OCR en erreur)
/// ne doit pas faire perdre la passe 1 : on continue sans lui.
Future<OcrPass?> _runRetry(
  TextRecognizer recognizer,
  File imageFile,
  Directory tempDir,
) async {
  final name = imageFile.uri.pathSegments.last;
  final enhancedFile = File('${tempDir.path}/retry_$name.jpg');
  try {
    final enhanced = await enhanceForRetry(await imageFile.readAsBytes());
    await enhancedFile.writeAsBytes(enhanced);
    return await _runPass(recognizer, enhancedFile);
  } catch (error, stackTrace) {
    debugPrint('retry impossible sur $name: $error\n$stackTrace');
    return null;
  } finally {
    if (enhancedFile.existsSync()) {
      await enhancedFile.delete();
    }
  }
}

Future<OcrPass> _runPass(TextRecognizer recognizer, File imageFile) async {
  final bytes = await imageFile.readAsBytes();
  final decoded = await decodeImageFromList(bytes);
  final imageWidth = decoded.width;
  final imageHeight = decoded.height;
  decoded.dispose();

  final stopwatch = Stopwatch()..start();
  final recognized = await recognizer.processImage(
    InputImage.fromFilePath(imageFile.path),
  );
  stopwatch.stop();

  return OcrPass(
    recognized: recognized,
    receipt: extractFromRecognized(recognized),
    latencyMs: stopwatch.elapsedMilliseconds,
    imageWidth: imageWidth,
    imageHeight: imageHeight,
  );
}

/// Noms de stage au format des scripts Python (snake_case) : le nom d'enum
/// Dart n'est pas le contrat.
const Map<FlowStage, String> _stageNames = {
  FlowStage.local: 'local',
  FlowStage.localRetry: 'local_retry',
  FlowStage.cloud: 'cloud',
  FlowStage.confirm: 'confirm',
};

Map<String, dynamic> flowJson(LocalScanResult result) {
  return {
    'stage': _stageNames[result.outcome.stage]!,
    'retryUsed': result.retryUsed,
    'pass1Ms': result.pass1.latencyMs,
    'retryMs': result.retry?.latencyMs,
    'pass1': receiptJson(result.pass1.receipt),
    'retry': switch (result.retry) {
      null => null,
      final retry => receiptJson(retry.receipt),
    },
    'outcome': {
      'stage': _stageNames[result.outcome.stage]!,
      'total': result.outcome.total,
      'items': [
        for (final item in result.outcome.items)
          {
            'name': item.name,
            'amount': item.amount,
            'discount': item.discount,
          },
      ],
    },
  };
}
