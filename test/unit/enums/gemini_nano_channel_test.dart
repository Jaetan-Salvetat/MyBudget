import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/gemini_nano_channel.dart';

void main() {
  group('GeminiNanoChannel', () {
    test('résout chaque identifiant persisté', () {
      for (final channel in GeminiNanoChannel.values) {
        expect(GeminiNanoChannel.fromId(channel.id), channel);
      }
    });

    test('retombe sur le canal stable pour un identifiant inconnu', () {
      expect(GeminiNanoChannel.fromId('beta'), GeminiNanoChannel.stable);
      expect(GeminiNanoChannel.fromId(null), GeminiNanoChannel.stable);
    });

    test('décrit chaque canal', () {
      for (final channel in GeminiNanoChannel.values) {
        expect(channel.label, isNotEmpty);
        expect(channel.description, isNotEmpty);
      }
    });
  });
}
