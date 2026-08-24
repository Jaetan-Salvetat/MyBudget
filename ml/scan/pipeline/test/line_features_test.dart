import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

void main() {
  group('block sum', () {
    test('total equals contiguous block above', () {
      expect(blockSumMatches([200, 300, -100, 400], 3), isTrue);
    });
    test('single line above does not count', () {
      expect(blockSumMatches([400, 400], 1), isFalse);
    });
    test('no block', () {
      expect(blockSumMatches([200, 300, 999], 2), isFalse);
    });
    test('first line has nothing above', () {
      expect(blockSumMatches([500], 0), isFalse);
    });
  });

  group('discount summary', () {
    test('negative equal to sum of previous negatives', () {
      expect(discountSummary([500, -100, 300, -55, -155], 4), isTrue);
    });
    test('single previous negative does not count', () {
      expect(discountSummary([500, -155, -155], 2), isFalse);
    });
    test('positive line is never a summary', () {
      expect(discountSummary([-100, -55, 155], 2), isFalse);
    });
  });

  group('tax shaped', () {
    test('ten percent of other', () {
      expect(taxShaped(66, [66, 664, 730]), isTrue);
    });
    test('twenty percent ttc decomposition', () {
      expect(taxShaped(700, [4200, 3500, 700]), isTrue);
    });
    test('ht of ttc', () {
      expect(taxShaped(3500, [4200, 3500]), isTrue);
    });
    test('unrelated', () {
      expect(taxShaped(123, [999, 500]), isFalse);
    });
  });

  group('fuzzy lexicon', () {
    test('exact word', () {
      expect(fuzzyLexiconSimilarity('TOTAL TTC 7.30', ['TOTAL']), 1.0);
    });
    test('ocr substitution', () {
      expect(
        fuzzyLexiconSimilarity('Tota1 HT 35,00', ['TOTAL']),
        greaterThanOrEqualTo(0.8),
      );
    });
    test('split word', () {
      expect(
        fuzzyLexiconSimilarity('TOT AL 12.00', ['TOTAL']),
        greaterThanOrEqualTo(0.8),
      );
    });
    test('unrelated text', () {
      expect(fuzzyLexiconSimilarity('BANANE 1.20', ['TOTAL']), lessThan(0.5));
    });
    test('short entries need exact match', () {
      expect(fuzzyLexiconSimilarity('MENTHE 2.00', ['HT']), 0.0);
      expect(fuzzyLexiconSimilarity('TOTAL HT 2.00', ['HT']), 1.0);
    });
    test('levenshtein', () {
      expect(levenshtein('TOTAL', 'TOTAL'), 0);
      expect(levenshtein('TOTAI', 'TOTAL'), 1);
      expect(levenshtein('', 'ABC'), 3);
    });
  });

  group('hashing', () {
    test('crc32 reference vector', () {
      expect(crc32('123456789'.codeUnits), 0xCBF43926);
    });
    test('deterministic and sized', () {
      final a = hashedTrigrams('TOTAL', 64);
      final b = hashedTrigrams('TOTAL', 64);
      expect(a, b);
      expect(a.length, 64);
      expect(a.reduce((x, y) => x + y), greaterThan(0));
    });
    test('digits are folded', () {
      expect(hashedTrigrams('ART 123', 64), hashedTrigrams('ART 456', 64));
    });
  });

  test('feature vector has the exported width', () {
    final merged = mergedLines([
      PhysicalLine(words: [
        const Word(text: 'PAIN', left: 0, top: 0, right: 50, bottom: 20, confidence: 0.9),
        const Word(text: '2,50', left: 300, top: 0, right: 350, bottom: 20, confidence: 0.9),
      ]),
      PhysicalLine(words: [
        const Word(text: 'TOTAL', left: 0, top: 40, right: 60, bottom: 60, confidence: 0.9),
        const Word(text: '2,50', left: 300, top: 40, right: 350, bottom: 60, confidence: 0.9),
      ]),
    ]);
    final (lines, rows) = featurize(merged);
    expect(lines.length, 2);
    expect(rows.every((row) => row.length == featureCount), isTrue);
    expect(rows[1][15], 1.0);
  });
}
