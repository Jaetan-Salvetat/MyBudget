import 'dart:convert';

import 'package:receipt_pipeline/receipt_pipeline.dart';

/// La trace de scan en texte brut, une ligne par fait.
///
/// L'inspecteur montre les mêmes données, mais un écran ne se relit pas hors
/// du téléphone : ce rapport se copie, se colle dans un ticket, et se rejoue
/// contre la référence Python. Chaque ligne porte le préfixe [reportTag] pour
/// être isolable d'un `logcat` bavard.
const String reportTag = '[scan-trace]';

/// Les fichiers déposés dans le stockage externe de l'app, à récupérer par
/// `adb pull` : le rapport à lire, et les mots à rejouer.
const String reportFileName = 'scan_trace.txt';
const String wordsFileName = 'scan_trace.json';

/// Les mots de chaque lecture, boîtes comprises, au format que la référence
/// Python sait relire.
///
/// Le rapport se lit mais ne se rejoue pas : sans géométrie, impossible de
/// refaire tourner le regroupement de lignes sur le cas qui a échoué. Ce sont
/// les mots d'après le déskew — l'entrée exacte de `clusterLines`.
String scanTraceWords(List<ReadTrace> trace) => const JsonEncoder.withIndent(
  '  ',
).convert({
  'reads': [
    for (final read in trace)
      {
        'source': sourceName(read.source),
        'words': [
          for (final line in read.lines)
            for (final word in line.words)
              {
                'text': word.text,
                'box': [word.left, word.top, word.right, word.bottom],
                if (word.confidence != null) 'confidence': word.confidence,
              },
        ],
      },
  ],
});

String scanTraceReport(List<ReadTrace> trace) {
  if (trace.isEmpty) return '$reportTag aucune lecture';
  final lines = <String>[];
  for (final read in trace) {
    lines.addAll(_readReport(read));
  }
  return lines.map((line) => '$reportTag $line').join('\n');
}

List<String> _readReport(ReadTrace read) {
  final decoding = read.decoding;
  final hypothesis = decoding.hypothesis;
  final roles = predictedRoles(read.roles);
  final priced = {for (final line in decoding.priced) line.index: line};
  final rank = {
    for (final (rank, line) in decoding.priced.indexed) line.index: rank,
  };

  return [
    '=== ${sourceName(read.source)} : '
        '${read.lines.length} lignes, '
        '${decoding.priced.length} chiffrées, '
        '${read.proved ? 'somme prouvée' : 'somme NON prouvée'}',
    if (hypothesis != null)
      '    référence ${_amount(hypothesis.referenceCents / 100)} '
          '(sources ${hypothesis.sources.map((s) => s.name).join(',')})',
    if (hypothesis == null) '    aucune hypothèse : rien ne referme la somme',
    for (final (index, line) in read.merged.indexed)
      _lineReport(index, line, roles[index], priced[index], rank[index],
          hypothesis, decoding),
  ];
}

String _lineReport(
  int index,
  PhysicalLine line,
  String role,
  PricedLine? priced,
  int? rank,
  Hypothesis? hypothesis,
  ReceiptDecoding decoding,
) {
  final buffer = StringBuffer('  ${index.toString().padLeft(3)} $role');
  if (priced != null) {
    buffer.write(
      ' | candidats ${[for (final c in priced.candidates) _amount(c)].join(',')}',
    );
    if (decoding.laxRanks.contains(index)) buffer.write(' lâche');
    if (hypothesis != null && rank != null) {
      buffer.write(' | décodé ${_label(hypothesis.labels[rank])}');
      if (hypothesis.cents.isNotEmpty) {
        buffer.write(' ${_amount(hypothesis.cents[rank] / 100)}');
      }
    }
  }
  buffer.write(' | ${line.text}');
  return buffer.toString();
}

String _label(int label) => switch (label) {
  labelItem => 'article',
  labelDiscount => 'remise',
  labelTotal => 'total',
  labelPayment => 'paiement',
  _ => 'ignorée',
};

String _amount(double value) => value.toStringAsFixed(2);
