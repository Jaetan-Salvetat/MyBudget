import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/quick_add/quick_add_tokenizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuickAddTokenizer tokenizer;

  setUpAll(() async {
    tokenizer = QuickAddTokenizer();
    await tokenizer.load();
  });

  group('QuickAddTokenizer', () {
    test('is loaded after load()', () {
      expect(tokenizer.isLoaded, isTrue);
    });

    test('pads output to fixed length', () {
      final output = tokenizer.encode('café');

      expect(output.inputIds.length, 64);
      expect(output.attentionMask.length, 64);
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
      for (int i = eosPosition + 1; i < 64; i++) {
        expect(output.inputIds[i], 0);
        expect(output.attentionMask[i], 0);
      }
    });

    test('truncates long input to max length ending with EOS', () {
      final longText = List.filled(200, 'restaurant').join(' ');
      final output = tokenizer.encode(longText);

      expect(output.inputIds.length, 64);
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
