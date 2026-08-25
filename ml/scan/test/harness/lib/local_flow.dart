import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

import 'ocr_dump.dart';
import 'preprocess.dart';

const String lineClassifierAsset = 'assets/models/line_clf_v3.json';

Future<LineClassifier>? _classifier;

/// Classifieur de lignes embarqué (JSON exporté depuis Python), chargé une
/// fois pour toute la session.
Future<LineClassifier> loadLineClassifier() {
  return _classifier ??= rootBundle
      .loadString(lineClassifierAsset)
      .then(
        (json) =>
            LineClassifier.fromJson(jsonDecode(json) as Map<String, dynamic>),
      );
}

class OcrPass {
  const OcrPass({
    required this.recognized,
    required this.lines,
    required this.receipt,
    required this.latencyMs,
    required this.imageWidth,
    required this.imageHeight,
  });

  final RecognizedText recognized;
  final List<PhysicalLine> lines;
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

/// Le flow local complet sur une image. Passe 1 : règles, puis classifieur
/// (argmax, décodage sous contrainte). Si rien ne vérifie, seulement alors
/// le retry prétraité — l'étage cher (2e OCR) — avec les mêmes étages, puis
/// la fusion des deux passes. Un stage `confirm` = non vérifié : dans
/// l'app, l'écran d'édition affiche un bandeau au lieu d'un badge.
Future<LocalScanResult> runLocalFlow(
  TextRecognizer recognizer,
  File imageFile,
  Directory tempDir,
) async {
  final classifier = await loadLineClassifier();
  final pass1 = await _runPass(recognizer, imageFile);
  var outcome = decideFirstPass(
    pass1.receipt,
    pass1.lines,
    classifier,
    FlowPolicy.recommended,
  );

  OcrPass? retry;
  if (!outcome.verified) {
    retry = await _runRetry(recognizer, imageFile, tempDir);
    if (retry != null) {
      outcome = decideRetryPass(
        pass1.receipt,
        retry.receipt,
        pass1.lines,
        retry.lines,
        classifier,
        FlowPolicy.recommended,
      );
    }
  }
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

  final lines = linesFromRecognized(recognized);
  return OcrPass(
    recognized: recognized,
    lines: lines,
    receipt: extract(lines),
    latencyMs: stopwatch.elapsedMilliseconds,
    imageWidth: imageWidth,
    imageHeight: imageHeight,
  );
}

Map<String, dynamic> flowJson(LocalScanResult result) {
  return {
    'stage': stageName(result.outcome.stage),
    'retryUsed': result.retryUsed,
    'pass1Ms': result.pass1.latencyMs,
    'retryMs': result.retry?.latencyMs,
    'pass1': receiptJson(result.pass1.receipt),
    'retry': switch (result.retry) {
      null => null,
      final retry => receiptJson(retry.receipt),
    },
    'outcome': {
      'stage': stageName(result.outcome.stage),
      'total': result.outcome.total,
      'items': [
        for (final item in result.outcome.items)
          {'name': item.name, 'amount': item.amount, 'discount': item.discount},
      ],
    },
  };
}
