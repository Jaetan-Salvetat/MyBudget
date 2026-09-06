import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/scan/widgets/scan_receipt_header.dart';
import 'package:mybudget/ui/scan/widgets/scan_reveal.dart';

void main() {
  group('ScanReveal', () {
    test('l\'en-tête voyage en premier et arrive avant la liste', () {
      expect(ScanReveal.headerProgressOf(0), 0);
      expect(ScanReveal.headerProgressOf(ScanReveal.headerEnd), 1);
      expect(
        ScanReveal.headerProgressOf(ScanReveal.listStart),
        greaterThan(0.99),
        reason: 'le montant est posé quand la liste commence à arriver',
      );
    });

    test('la liste n\'entre pas avant son tour', () {
      expect(ScanReveal.listProgressOf(0), 0);
      expect(ScanReveal.listProgressOf(ScanReveal.listStart), 0);
      expect(ScanReveal.listProgressOf(1), 1);
      expect(ScanReveal.rowProgressOf(ScanReveal.listStart, 0), 0);
    });

    test('les lignes se posent l\'une après l\'autre', () {
      const midway = 0.6;

      expect(
        ScanReveal.rowProgressOf(midway, 0),
        greaterThan(ScanReveal.rowProgressOf(midway, 3)),
      );
      expect(ScanReveal.rowProgressOf(1, 0), 1);
      expect(ScanReveal.rowProgressOf(1, ScanReveal.rowSpanCount), 1);
    });

    test('la cascade cesse de s\'allonger passé son rang de coupe', () {
      const midway = 0.85;

      expect(
        ScanReveal.rowProgressOf(midway, 40),
        ScanReveal.rowProgressOf(midway, ScanReveal.rowSpanCount),
        reason: 'un ticket de quarante articles se pose comme un de huit',
      );
    });

    test('l\'en-tête part du milieu de l\'écran et finit en haut', () {
      const height = 800.0;
      final centered = (height - ScanReceiptHeader.height) / 2;

      expect(ScanReveal.headerOffsetOf(height, 0), centered);
      expect(ScanReveal.headerOffsetOf(height, 1), 0);
      expect(
        ScanReveal.headerOffsetOf(height, ScanReveal.headerEnd),
        moreOrLessEquals(0, epsilon: 0.001),
      );
    });

    test('un écran trop court ne décale rien', () {
      expect(ScanReveal.headerOffsetOf(ScanReceiptHeader.height, 0), 0);
      expect(ScanReveal.headerOffsetOf(0, 0), 0);
    });
  });
}
