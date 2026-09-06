import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

class _FakeClassifier implements ReceiptLineClassifier {
  final Map<String, LinePrediction> answers;
  final List<String> seen = [];

  _FakeClassifier(this.answers);

  @override
  Future<LinePrediction> classify(String normalizedLine) async {
    seen.add(normalizedLine);
    return answers[normalizedLine] ?? (slug: 'divers.autre', confidence: 0.1);
  }
}

void main() {
  group('ReceiptCategorizer', () {
    test('normalizes each line before the model and keeps its order', () async {
      final classifier = _FakeClassifier({
        'litiere silice pour chat u': (slug: 'divers.animaux', confidence: 0.9),
        'blc plt .f': (slug: 'alimentation.supermarche', confidence: 0.7),
      });

      final result = await ReceiptCategorizer(classifier).categorize([
        'LITIERE SILICE POUR CHAT U 5L',
        '*160G BLC PLT 4TR.F',
      ]);

      expect([for (final item in result) item.slug], [
        'divers.animaux',
        'alimentation.supermarche',
      ]);
      expect(classifier.seen, [
        'litiere silice pour chat u',
        'blc plt .f',
      ]);
    });

    test('classes an article on itself, never on what sits next to it', () async {
      final classifier = _FakeClassifier({
        'menu supreme': (slug: 'restauration.fast_food', confidence: 0.9),
        'croquettes chat': (slug: 'divers.animaux', confidence: 0.6),
      });

      final result = await ReceiptCategorizer(
        classifier,
      ).categorize(['1 MENU SUPREME', 'CROQUETTES CHAT']);

      expect(result[0].slug, 'restauration.fast_food');
      expect(result[1].slug, 'divers.animaux');
      expect(result[1].confidence, 0.6);
    });

    test('reads nothing when there is no article', () async {
      final classifier = _FakeClassifier(const {});
      expect(await ReceiptCategorizer(classifier).categorize(const []), isEmpty);
      expect(classifier.seen, isEmpty);
    });
  });
}
