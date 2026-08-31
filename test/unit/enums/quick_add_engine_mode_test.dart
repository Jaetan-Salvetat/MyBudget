import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';

void main() {
  group('QuickAddEngineMode', () {
    test('résout chaque identifiant persisté', () {
      for (final mode in QuickAddEngineMode.values) {
        expect(QuickAddEngineMode.fromId(mode.id), mode);
      }
    });

    test('retombe sur le modèle embarqué pour un identifiant inconnu', () {
      expect(QuickAddEngineMode.fromId('nano'), QuickAddEngineMode.onDevice);
      expect(QuickAddEngineMode.fromId(null), QuickAddEngineMode.onDevice);
    });

    test('ne recommande que Gemini Nano', () {
      expect(
        QuickAddEngineMode.values.where((mode) => mode.isRecommended),
        [QuickAddEngineMode.geminiNano],
      );
    });

    test('présente Gemini Nano en premier', () {
      expect(QuickAddEngineMode.values.first, QuickAddEngineMode.geminiNano);
    });
  });
}
