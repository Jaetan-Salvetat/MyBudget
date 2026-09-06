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
  });
}
