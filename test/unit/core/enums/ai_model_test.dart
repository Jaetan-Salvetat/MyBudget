import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/enums/ai_provider.dart';

void main() {
  group('AiModel', () {
    test('exposes the four selectable Gemini models', () {
      expect(
        AiModel.values.map((model) => model.id),
        containsAll(<String>[
          'gemini-3.7-flash',
          'gemini-3.6-flash',
          'gemini-3.5-flash',
          'gemini-3.5-flash-lite',
        ]),
      );
    });

    test('every model belongs to a provider', () {
      expect(
        AiModel.values.every((model) => model.provider == AiProvider.gemini),
        isTrue,
      );
    });

    test('fromId returns the matching model', () {
      expect(AiModel.fromId('gemini-3.7-flash'), AiModel.flash37);
    });

    test('the most recent flash-lite is the default', () {
      expect(AiModel.fallback, AiModel.flashLite35);
    });

    test('fromId falls back on an unknown or missing id', () {
      expect(AiModel.fromId('gemini-9-turbo'), AiModel.fallback);
      expect(AiModel.fromId(null), AiModel.fallback);
    });

    test('forProvider lists only that provider models', () {
      final models = AiModel.forProvider(AiProvider.gemini);

      expect(models, isNotEmpty);
      expect(models.every((m) => m.provider == AiProvider.gemini), isTrue);
    });

    test('defaultFor returns a model of the asked provider', () {
      expect(AiModel.defaultFor(AiProvider.gemini).provider, AiProvider.gemini);
    });

    test('labels and descriptions are filled for every model', () {
      for (final model in AiModel.values) {
        expect(model.label, isNotEmpty);
        expect(model.description, isNotEmpty);
      }
    });
  });
}
