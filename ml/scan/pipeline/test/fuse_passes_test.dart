import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

import 'support.dart';

List<String> texts(FusedPass fused) => [for (final l in fused.lines) l.text];

void main() {
  group('fusePasses', () {
    test('identical passes keep the primary', () {
      final rows = [
        [('STORE', 10)],
        [('PAIN', 0), ('2,50', 38)],
        [('TOTAL', 0), ('2,50', 38)],
      ];
      final fused = fusePasses(receiptLines(rows), receiptLines(rows));
      expect(texts(fused), ['STORE', 'PAIN 2,50', 'TOTAL 2,50']);
      expect(fused.alternatives, isEmpty);
    });

    test('differing amount on the same line becomes an alternative', () {
      final primary = receiptLines([
        [('STORE', 10)],
        [('TORT', 0), ('RICOTTA', 5), ('S2.75e', 36)],
        [('TOTAL', 0), ('2,75', 38)],
      ]);
      final secondary = receiptLines([
        [('STORE', 10)],
        [('TORT', 0), ('RICOTTA', 5), ('2.75€', 36)],
        [('TOTAL', 0), ('2,75', 38)],
      ]);
      final fused = fusePasses(primary, secondary);
      expect(texts(fused)[1], 'TORT RICOTTA S2.75e');
      expect(fused.alternatives, {1: 275});
    });

    test('unpriced primary line is replaced by the priced secondary', () {
      final primary = receiptLines([
        [('STORE', 10)],
        [('SALAD', 0), ('VENEZIA', 6), ('4.236', 36)],
        [('TOTAL', 0), ('4,23', 38)],
      ]);
      final secondary = receiptLines([
        [('STORE', 10)],
        [('SALAD', 0), ('VENEZIA', 6), ('4.23€', 36)],
        [('TOTAL', 0), ('4,23', 38)],
      ]);
      final fused = fusePasses(primary, secondary);
      expect(texts(fused), ['STORE', 'SALAD VENEZIA 4.23€', 'TOTAL 4,23']);
      expect(fused.alternatives, isEmpty);
    });

    test('secondary only line is inserted in reading order', () {
      final primary = [
        line(0, [('STORE', 10)]),
        line(1, [('PAIN', 0), ('2,50', 38)]),
        line(3, [('TOTAL', 0), ('3,70', 38)]),
      ];
      final secondary = [
        line(0, [('STORE', 10)]),
        line(1, [('PAIN', 0), ('2,50', 38)]),
        line(2, [('LAIT', 0), ('1,20', 38)]),
        line(3, [('TOTAL', 0), ('3,70', 38)]),
      ];
      final fused = fusePasses(primary, secondary);
      expect(texts(fused), ['STORE', 'PAIN 2,50', 'LAIT 1,20', 'TOTAL 3,70']);
    });

    test('primary line holding two prices is split by the secondary', () {
      final primary = [
        line(0, [('STORE', 10)]),
        line(1, [('KINDER', 0), ('LEFFE', 8), ('10.50€', 28), ('5.95€', 36)]),
        line(2, [('TOTAL', 0), ('16,45', 38)]),
      ];
      final secondary = [
        line(0, [('STORE', 10)]),
        line(0.8, [('KINDER', 0), ('5.95€', 36)]),
        line(1.2, [('LEFFE', 0), ('10.50€', 36)]),
        line(2, [('TOTAL', 0), ('16,45', 38)]),
      ];
      final fused = fusePasses(primary, secondary);
      expect(texts(fused), [
        'STORE',
        'KINDER 5.95€',
        'LEFFE 10.50€',
        'TOTAL 16,45',
      ]);
    });

    test('secondary line far from any primary line is not a match', () {
      final primary = [
        line(0, [('STORE', 10)]),
        line(1, [('PAIN', 0), ('2,50', 38)]),
      ];
      final secondary = [
        line(0, [('STORE', 10)]),
        line(1, [('PAIN', 0), ('2,60', 38)]),
        line(4, [('TOTAL', 0), ('2,60', 38)]),
      ];
      final fused = fusePasses(primary, secondary);
      expect(texts(fused), ['STORE', 'PAIN 2,50', 'TOTAL 2,60']);
      expect(fused.alternatives, {1: 260});
    });
  });
}
