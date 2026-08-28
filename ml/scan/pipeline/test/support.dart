import 'package:receipt_pipeline/receipt_pipeline.dart';

const double lineHeight = 30.0;
const double charWidth = 14.0;

Word word(String text, int column, num row) {
  final left = column * charWidth;
  final top = row * (lineHeight + 8);
  return Word(
    text: text,
    left: left,
    top: top,
    right: left + text.length * charWidth,
    bottom: top + lineHeight,
    confidence: 0.9,
  );
}

PhysicalLine line(num row, List<(String, int)> tokens) {
  return PhysicalLine(
    words: [for (final (text, column) in tokens) word(text, column, row)],
  );
}

List<PhysicalLine> receiptLines(List<List<(String, int)>> rows) {
  return [for (final (index, tokens) in rows.indexed) line(index, tokens)];
}

List<(String, double)> namedAmounts(ExtractedReceipt receipt) => [
  for (final item in receipt.items) (item.name, item.amount),
];

List<PricedLine> priced(List<List<(String, int)>> rows) =>
    pricedLines(receiptLines(rows));
