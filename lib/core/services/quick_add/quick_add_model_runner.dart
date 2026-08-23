import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:mybudget/core/services/quick_add/quick_add_tokenizer.dart';
import 'package:path_provider/path_provider.dart';

typedef TempDirectoryResolver = Future<Directory> Function();

typedef HeadPrediction = ({int index, double confidence});

/// Category prediction with its runners-up, used to seed the picker when
/// confidence is too low to assign automatically.
typedef CategoryPrediction = ({
  int index,
  double confidence,
  List<int> topIndices,
});

typedef QuickAddModelOutput = ({
  HeadPrediction type,
  CategoryPrediction category,
  HeadPrediction recurrence,
});

const int kCategorySuggestionCount = 3;

class QuickAddModelRunner {
  /// Le plugin ONNX extrait l'asset dans le dossier temporaire et le met en
  /// cache sous son seul nom de fichier : republier un modele reentraine sous
  /// le meme nom laisserait toutes les installations existantes tourner sur
  /// l'ancien. La version dans le nom donne a chaque modele sa propre entree
  /// de cache — a incrementer a chaque nouveau modele.
  static const String assetPath = 'assets/models/model_v2.onnx';

  static final RegExp _extractionPattern = RegExp(r'^model(_v\d+)?\.onnx$');

  final OnnxRuntime _ort;
  final TempDirectoryResolver _tempDirectory;
  OrtSession? _session;

  QuickAddModelRunner(this._ort, {TempDirectoryResolver? tempDirectory})
    : _tempDirectory = tempDirectory ?? getTemporaryDirectory;

  bool get isLoaded => _session != null;

  Future<void> load() async {
    if (_session != null) return;
    await _deleteOutdatedExtractions();
    _session = await _ort.createSessionFromAsset(assetPath);
  }

  /// Les extractions des versions precedentes pesent autant que le modele :
  /// les laisser dans le cache doublerait l'espace occupe a chaque mise a
  /// jour. Un echec de nettoyage ne doit pas priver l'utilisateur de l'ajout
  /// rapide, on le signale et on charge quand meme.
  Future<void> _deleteOutdatedExtractions() async {
    final currentName = assetPath.split('/').last;
    try {
      final directory = await _tempDirectory();
      await for (final entry in directory.list()) {
        final name = entry.path.split(Platform.pathSeparator).last;
        if (entry is! File) continue;
        if (name == currentName || !_extractionPattern.hasMatch(name)) continue;
        await entry.delete();
      }
    } on FileSystemException catch (error, stackTrace) {
      debugPrint('Nettoyage des modeles caches impossible : '
          '$error\n$stackTrace');
    }
  }

  Future<QuickAddModelOutput> run(TokenizedInput tokens) async {
    final session = _session;
    if (session == null) {
      throw StateError('Model not loaded. Call load() first.');
    }

    final inputIds = await OrtValue.fromList(
      Int64List.fromList(tokens.inputIds),
      [1, tokens.inputIds.length],
    );
    final attentionMask = await OrtValue.fromList(
      Int64List.fromList(tokens.attentionMask),
      [1, tokens.attentionMask.length],
    );

    try {
      final outputs = await session.run({
        'input_ids': inputIds,
        'attention_mask': attentionMask,
      });

      final typeLogits = await _extractLogits(outputs, 'type_logits');
      final catLogits = await _extractLogits(outputs, 'category_logits');
      final recLogits = await _extractLogits(outputs, 'recurrence_logits');

      for (final output in outputs.values) {
        await output.dispose();
      }

      return (
        type: _argmaxWithConfidence(typeLogits),
        category: _topCategories(catLogits),
        recurrence: _argmaxWithConfidence(recLogits),
      );
    } finally {
      await inputIds.dispose();
      await attentionMask.dispose();
    }
  }

  Future<List<double>> _extractLogits(
    Map<String, OrtValue> outputs,
    String name,
  ) async {
    final value = outputs[name];
    if (value == null) {
      throw StateError('Missing model output: $name');
    }
    final flat = await value.asFlattenedList();
    return flat.cast<double>();
  }

  HeadPrediction _argmaxWithConfidence(List<double> logits) {
    final probs = _softmax(logits);
    int maxIdx = 0;
    double maxVal = probs[0];
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > maxVal) {
        maxVal = probs[i];
        maxIdx = i;
      }
    }
    return (index: maxIdx, confidence: maxVal);
  }

  CategoryPrediction _topCategories(List<double> logits) {
    final probs = _softmax(logits);
    final ranked = List<int>.generate(probs.length, (i) => i)
      ..sort((a, b) => probs[b].compareTo(probs[a]));
    final top = ranked.take(kCategorySuggestionCount).toList();
    return (index: top.first, confidence: probs[top.first], topIndices: top);
  }

  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((l) => math.exp(l - maxLogit)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  Future<void> dispose() async {
    await _session?.close();
    _session = null;
  }
}
