/// Rejoue le pipeline Dart sur des dumps OCR du harnais et écrit, par
/// ticket, l'extraction de la passe 1 et — si un modèle est fourni — la
/// décision du flow local complet (règles → retry → classifieur → décodeur),
/// pour comparaison champ à champ avec la version Python
/// (analysis/check_parity.py).
library;

import 'dart:convert';
import 'dart:io';

import 'package:receipt_pipeline/receipt_pipeline.dart';

const String modelOption = '--model=';

void main(List<String> args) {
  final dirs = args.where((arg) => !arg.startsWith(modelOption)).toList();
  final modelPath = args
      .where((arg) => arg.startsWith(modelOption))
      .map((arg) => arg.substring(modelOption.length))
      .firstOrNull;
  if (dirs.isEmpty) {
    stderr.writeln('usage: dart tool/parity.dart [--model=path] <results_dir>...');
    exitCode = 2;
    return;
  }
  final classifier = modelPath == null
      ? null
      : LineClassifier.fromJson(
          jsonDecode(File(modelPath).readAsStringSync()) as Map<String, dynamic>,
        );
  final output = <String, Object?>{};
  for (final dirPath in dirs) {
    final files = Directory(dirPath)
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final data = jsonDecode(file.readAsStringSync());
      if (data is! Map<String, dynamic> || data['blocks'] == null) continue;
      final pass1 = clusteredLines(data);
      final entry = <String, Object?>{'pass1': receiptJson(extract(pass1))};
      if (classifier != null) {
        entry['flow'] = _flowJson(data, pass1, classifier);
      }
      output['$dirPath/${file.uri.pathSegments.last}'] = entry;
    }
  }
  stdout.writeln(jsonEncode(output));
}

Map<String, Object?> _flowJson(
  Map<String, dynamic> data,
  List<PhysicalLine> pass1,
  LineClassifier classifier,
) {
  final retryData = data['ocrRetry'] as Map<String, dynamic>?;
  final retry = retryData == null ? null : clusteredLines(retryData);
  final outcome = decide(
    extract(pass1),
    retry == null ? null : extract(retry),
    FlowPolicy.recommended,
    rescue: classifierRescue([pass1, ?retry], classifier),
  );
  return {
    'stage': stageName(outcome.stage),
    'total': outcome.total,
    'items': [
      for (final item in outcome.items)
        {'amount': item.amount, 'discount': item.discount},
    ],
  };
}

/// Lignes physiques d'un dump OCR (mots + angle médian), comme sur device.
List<PhysicalLine> clusteredLines(Map<String, dynamic> data) {
  final words = <Word>[];
  final angles = <double>[];
  for (final block in data['blocks'] as List<dynamic>) {
    for (final line in (block as Map<String, dynamic>)['lines']
        as List<dynamic>) {
      final lineMap = line as Map<String, dynamic>;
      final angle = lineMap['angle'];
      if (angle != null) angles.add((angle as num).toDouble());
      for (final element in lineMap['elements'] as List<dynamic>) {
        final elementMap = element as Map<String, dynamic>;
        final box = (elementMap['box'] as List<dynamic>)
            .map((value) => (value as num).toDouble())
            .toList();
        words.add(
          Word(
            text: elementMap['text'] as String,
            left: box[0],
            top: box[1],
            right: box[2],
            bottom: box[3],
            confidence: (elementMap['confidence'] as num?)?.toDouble(),
          ),
        );
      }
    }
  }
  return clusterLines(deskewWords(words, medianAngle(angles)));
}
