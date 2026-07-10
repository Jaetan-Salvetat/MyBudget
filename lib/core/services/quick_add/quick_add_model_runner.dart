import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:mybudget/core/services/quick_add/quick_add_tokenizer.dart';

typedef HeadPrediction = ({int index, double confidence});

typedef QuickAddModelOutput = ({
  HeadPrediction type,
  HeadPrediction category,
  HeadPrediction recurrence,
});

class QuickAddModelRunner {
  static const String assetPath = 'assets/models/model.onnx';

  final OnnxRuntime _ort;
  OrtSession? _session;

  QuickAddModelRunner(this._ort);

  bool get isLoaded => _session != null;

  Future<void> load() async {
    if (_session != null) return;
    _session = await _ort.createSessionFromAsset(assetPath);
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
        category: _argmaxWithConfidence(catLogits),
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
