/// Rejoue les features, le tagger de rôles, le modèle de lien et le tagger de
/// spans côté Dart,
/// pour comparaison ligne à ligne avec la référence Python
/// (research/bench/roles_parity.py).
///
/// Entrée : les fichiers du corpus annoté, qui portent déjà les lignes
/// physiques avec leur géométrie. Sortie : par ticket, la matrice de
/// features de ligne et de mot, le rôle le plus probable de chaque ligne, la
/// distance prédite jusqu'à son libellé et le libellé découpé. Zéro divergence attendue — une colonne décalée fait
/// décider le device autrement que la référence.
library;

import 'dart:convert';
import 'dart:io';

import 'package:receipt_pipeline/receipt_pipeline.dart';

const String modelOption = '--model=';
const String linkOption = '--link=';
const String spanOption = '--span=';

PhysicalLine _lineOf(Map<String, dynamic> line) => PhysicalLine(
  words: [
    for (final word in line['words'] as List<dynamic>)
      Word(
        text: (word as Map<String, dynamic>)['text'] as String,
        left: ((word['box'] as List<dynamic>)[0] as num).toDouble(),
        top: ((word['box'] as List<dynamic>)[1] as num).toDouble(),
        right: ((word['box'] as List<dynamic>)[2] as num).toDouble(),
        bottom: ((word['box'] as List<dynamic>)[3] as num).toDouble(),
        confidence: (word['confidence'] as num?)?.toDouble(),
      ),
  ],
);

void main(List<String> args) {
  final dirs = args
      .where(
        (arg) =>
            !arg.startsWith(modelOption) &&
            !arg.startsWith(linkOption) &&
            !arg.startsWith(spanOption),
      )
      .toList();
  final modelPath = args
      .where((arg) => arg.startsWith(modelOption))
      .map((arg) => arg.substring(modelOption.length))
      .firstOrNull;
  final linkPath = args
      .where((arg) => arg.startsWith(linkOption))
      .map((arg) => arg.substring(linkOption.length))
      .firstOrNull;
  final spanPath = args
      .where((arg) => arg.startsWith(spanOption))
      .map((arg) => arg.substring(spanOption.length))
      .firstOrNull;
  if (dirs.isEmpty ||
      modelPath == null ||
      linkPath == null ||
      spanPath == null) {
    stderr.writeln(
      'usage: dart tool/roles_parity.dart --model=<line_roles.json> '
      '--link=<label_link.json> --span=<label_span.json> <dir>...',
    );
    exitCode = 2;
    return;
  }
  final tagger = LineClassifier.fromJson(
    jsonDecode(File(modelPath).readAsStringSync()) as Map<String, dynamic>,
  );
  final link = LabelLinkModel(
    LineClassifier.fromJson(
      jsonDecode(File(linkPath).readAsStringSync()) as Map<String, dynamic>,
    ),
  );

  final spanner = LabelSpanModel(
    LineClassifier.fromJson(
      jsonDecode(File(spanPath).readAsStringSync()) as Map<String, dynamic>,
    ),
  );

  final output = <String, Object?>{};
  for (final dirPath in dirs) {
    final files =
        Directory(dirPath)
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final data = jsonDecode(file.readAsStringSync());
      if (data is! Map<String, dynamic> || data['lines'] == null) continue;
      final lines = [
        for (final line in data['lines'] as List<dynamic>)
          _lineOf(line as Map<String, dynamic>),
      ];
      if (lines.isEmpty) continue;
      final rows = featurizeAll(lines);
      final spans = spanner.probabilities(lines);
      output[file.uri.pathSegments.last] = {
        'features': rows,
        'roles': [for (final row in rows) argmax(tagger.predictProba(row))],
        'labelOffsets': link.offsets(lines),
        'wordFeatures': featurizeWords(lines),
        'labels': [
          for (var index = 0; index < lines.length; index++)
            labelOf(lines[index], spans[index]),
        ],
      };
    }
  }
  stdout.write(jsonEncode(output));
}
