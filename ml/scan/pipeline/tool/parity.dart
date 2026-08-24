/// Rejoue le pipeline Dart sur des dumps OCR du harnais et écrit une
/// extraction par ticket, pour comparaison champ à champ avec la version
/// Python (analysis/check_parity.py).
library;

import 'dart:convert';
import 'dart:io';

import 'package:receipt_pipeline/receipt_pipeline.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: dart tool/parity.dart <results_dir>...');
    exitCode = 2;
    return;
  }
  final output = <String, Object?>{};
  for (final dirPath in args) {
    final dir = Directory(dirPath);
    final files = dir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final data = jsonDecode(file.readAsStringSync());
      if (data is! Map<String, dynamic> || data['blocks'] == null) continue;
      final receipt = _extractFromDump(data);
      final key = file.uri.pathSegments.last;
      output['$dirPath/$key'] = receiptJson(receipt);
    }
  }
  stdout.writeln(jsonEncode(output));
}

ExtractedReceipt _extractFromDump(Map<String, dynamic> data) {
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
  final deskewed = deskewWords(words, medianAngle(angles));
  return extract(clusterLines(deskewed));
}

