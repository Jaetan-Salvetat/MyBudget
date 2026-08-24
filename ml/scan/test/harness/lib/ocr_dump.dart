import 'dart:math';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

/// Mots et angles au format du pipeline, depuis la sortie ML Kit brute.
List<Word> wordsFrom(RecognizedText recognized) {
  return [
    for (final block in recognized.blocks)
      for (final line in block.lines)
        for (final element in line.elements)
          Word(
            text: element.text,
            left: element.boundingBox.left,
            top: element.boundingBox.top,
            right: element.boundingBox.right,
            bottom: element.boundingBox.bottom,
            confidence: element.confidence,
          ),
  ];
}

List<double> anglesFrom(RecognizedText recognized) {
  return [
    for (final block in recognized.blocks)
      for (final line in block.lines)
        if (line.angle != null) line.angle!,
  ];
}

ExtractedReceipt extractFromRecognized(RecognizedText recognized) {
  final words = deskewWords(
    wordsFrom(recognized),
    medianAngle(anglesFrom(recognized)),
  );
  return extract(clusterLines(words));
}

/// Dump JSON complet de la sortie ML Kit, au format historique consommé par
/// les scripts Python (lines.load_words) : ne pas changer les clés.
Map<String, dynamic> ocrDumpJson({
  required String name,
  required int imageWidth,
  required int imageHeight,
  required int latencyMs,
  required RecognizedText recognized,
}) {
  int lineCount = 0;
  final blocks = recognized.blocks.map((block) {
    lineCount += block.lines.length;
    return {
      'text': block.text,
      'box': _rect(block.boundingBox),
      'corners': _points(block.cornerPoints),
      'languages': block.recognizedLanguages,
      'lines': block.lines.map(_lineJson).toList(),
    };
  }).toList();

  return {
    'image': name,
    'imageWidth': imageWidth,
    'imageHeight': imageHeight,
    'latencyMs': latencyMs,
    'lineCount': lineCount,
    'fullText': recognized.text,
    'blocks': blocks,
  };
}

Map<String, dynamic> _lineJson(TextLine line) {
  return {
    'text': line.text,
    'box': _rect(line.boundingBox),
    'corners': _points(line.cornerPoints),
    'confidence': line.confidence,
    'angle': line.angle,
    'elements': line.elements.map(_elementJson).toList(),
  };
}

Map<String, dynamic> _elementJson(TextElement element) {
  return {
    'text': element.text,
    'box': _rect(element.boundingBox),
    'corners': _points(element.cornerPoints),
    'confidence': element.confidence,
    'angle': element.angle,
    'symbols': element.symbols
        .map(
          (symbol) => {
            'text': symbol.text,
            'box': _rect(symbol.boundingBox),
            'confidence': symbol.confidence,
          },
        )
        .toList(),
  };
}

List<double> _rect(Rect rect) => [rect.left, rect.top, rect.right, rect.bottom];

List<List<int>> _points(List<Point<int>> points) =>
    points.map((point) => [point.x, point.y]).toList();
