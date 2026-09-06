import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/quick_add/quick_add_tokenizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuickAddTokenizer tokenizer;

  setUpAll(() async {
    tokenizer = QuickAddTokenizer();
    await tokenizer.load();
  });

  int lastBucket() => QuickAddTokenizer.lengthBuckets.last;

  group('QuickAddTokenizer', () {
    test('is loaded after load()', () {
      expect(tokenizer.isLoaded, isTrue);
    });

    test('pads a short input to the smallest bucket', () {
      final output = tokenizer.encode('café');

      expect(output.inputIds.length, QuickAddTokenizer.lengthBuckets.first);
      expect(
        output.attentionMask.length,
        QuickAddTokenizer.lengthBuckets.first,
      );
    });

    test('pads to a bucket that fits when the input overflows the first', () {
      final text = List.filled(10, 'restaurant').join(' ');
      final output = tokenizer.encode(text);

      expect(
        output.inputIds.length,
        greaterThan(QuickAddTokenizer.lengthBuckets.first),
      );
      expect(QuickAddTokenizer.lengthBuckets, contains(output.inputIds.length));
    });

    test('always lands on a declared bucket', () {
      for (var words = 1; words <= 40; words++) {
        final output = tokenizer.encode(List.filled(words, 'loyer').join(' '));

        expect(
          QuickAddTokenizer.lengthBuckets,
          contains(output.inputIds.length),
          reason: '$words mots',
        );
        expect(output.attentionMask.length, output.inputIds.length);
      }
    });

    test('picks the smallest bucket that fits', () {
      for (var words = 1; words <= 40; words++) {
        final output = tokenizer.encode(List.filled(words, 'loyer').join(' '));
        final realTokens = output.attentionMask.where((m) => m == 1).length;
        final smallestFitting = QuickAddTokenizer.lengthBuckets.firstWhere(
          (bucket) => realTokens <= bucket,
          orElse: lastBucket,
        );

        expect(
          output.inputIds.length,
          smallestFitting,
          reason: '$words mots, $realTokens tokens reels',
        );
      }
    });

    test('starts with BOS and contains EOS', () {
      final output = tokenizer.encode('netflix');

      expect(output.inputIds.first, 2);
      expect(output.inputIds.contains(1), isTrue);
    });

    test('attention mask matches non-padding tokens', () {
      final output = tokenizer.encode('courses carrefour');

      final eosPosition = output.inputIds.indexOf(1);
      for (int i = 0; i <= eosPosition; i++) {
        expect(output.attentionMask[i], 1);
      }
      for (int i = eosPosition + 1; i < output.inputIds.length; i++) {
        expect(output.inputIds[i], 0);
        expect(output.attentionMask[i], 0);
      }
    });

    test('truncates long input to max length ending with EOS', () {
      final longText = List.filled(200, 'restaurant').join(' ');
      final output = tokenizer.encode(longText);

      expect(output.inputIds.length, lastBucket());
      expect(output.inputIds.last, 1);
      expect(output.attentionMask.every((m) => m == 1), isTrue);
    });

    test('same input produces same encoding', () {
      final first = tokenizer.encode('loyer appartement');
      final second = tokenizer.encode('loyer appartement');

      expect(first.inputIds, second.inputIds);
      expect(first.attentionMask, second.attentionMask);
    });
  });
}
