import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

void main() {
  group('normalisation', () {
    test('accents and OCR substitutions fold together', () {
      expect(normalizedText('Café 015'), 'CAFE OIS');
    });
  });

  group('hashing', () {
    test('crc32 reference vector', () {
      expect(crc32('123456789'.codeUnits), 0xCBF43926);
    });
    test('deterministic and sized', () {
      final a = hashedTrigrams('TOTAL', hashBuckets);
      final b = hashedTrigrams('TOTAL', hashBuckets);
      expect(a, b);
      expect(a.length, hashBuckets);
      expect(a.reduce((x, y) => x + y), greaterThan(0));
    });
    test('digits are folded', () {
      expect(
        hashedTrigrams('ART 123', hashBuckets),
        hashedTrigrams('ART 456', hashBuckets),
      );
    });
  });
}
