import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';

void main() {
  group('AiRequestFailure.label', () {
    test('chaque panne se dit en clair', () {
      for (final failure in AiRequestFailure.values) {
        expect(failure.label, isNotEmpty, reason: failure.name);
      }
    });

    test('deux pannes ne se disent jamais pareil', () {
      final labels = AiRequestFailure.values
          .map((failure) => failure.label)
          .toSet();

      expect(labels.length, AiRequestFailure.values.length);
    });

    test('une clé refusée le dit à l\'utilisateur', () {
      expect(AiRequestFailure.invalidKey.label.toLowerCase(), contains('clé'));
    });
  });
}
