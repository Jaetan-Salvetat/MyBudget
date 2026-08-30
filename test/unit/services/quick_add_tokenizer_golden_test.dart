import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/quick_add/quick_add_tokenizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuickAddTokenizer tokenizer;
  late Map<String, dynamic> golden;

  setUpAll(() async {
    tokenizer = QuickAddTokenizer();
    await tokenizer.load();
    golden =
        json.decode(
              File('test/fixtures/tokenizer_golden.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
  });

  test('encode comme le tokenizer HuggingFace sur tout le corpus', () {
    expect(golden, isNotEmpty);

    for (final entry in golden.entries) {
      final expected = entry.value as Map<String, dynamic>;
      final output = tokenizer.encode(entry.key);

      expect(
        output.inputIds,
        expected['inputIds'],
        reason: 'inputIds pour "${entry.key}"',
      );
      expect(
        output.attentionMask,
        expected['attentionMask'],
        reason: 'attentionMask pour "${entry.key}"',
      );
    }
  });
}
