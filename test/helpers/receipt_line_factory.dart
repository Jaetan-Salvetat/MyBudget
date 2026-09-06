import 'package:receipt_pipeline/receipt_pipeline.dart';

const double _lineHeight = 30.0;
const double _charWidth = 14.0;
const double _lineGap = 8.0;

Word receiptWord(String text, int column, int row) {
  final left = column * _charWidth;
  final top = row * (_lineHeight + _lineGap);
  return Word(
    text: text,
    left: left,
    top: top,
    right: left + text.length * _charWidth,
    bottom: top + _lineHeight,
    confidence: 0.9,
  );
}

List<PhysicalLine> receiptLinesOf(List<List<(String, int)>> rows) => [
  for (final (index, tokens) in rows.indexed)
    PhysicalLine(
      words: [
        for (final (text, column) in tokens) receiptWord(text, column, index),
      ],
    ),
];
