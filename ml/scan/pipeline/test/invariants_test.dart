import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('tax evidence', () {
    test('ht line plus tva line proves the ttc', () {
      final lines = priced([
        [('CAFE', 0), ('4.50', 38)],
        [('CHOCOLAT', 0), ('5.80', 38)],
        [('TVA', 0), ('10%', 4), ('0.94', 38)],
        [('HT', 0), ('9.36', 38)],
        [('10.30', 38)],
      ]);
      final (evidence, ignored) = taxEvidence(lines);
      expect(evidence!.cents, 1030);
      expect(evidence.source, EvidenceSource.tax);
      expect(evidence.cutoffRank, 2);
      expect(ignored, {2, 3});
    });

    test('multi rate decomposition sums the ttc', () {
      final lines = priced([
        [('PDJ', 0), ('2.40', 38)],
        [('0.12', 0), ('TVA', 5), ('10%', 9), ('1.32', 38)],
        [('TTL', 0), ('Net', 4), ('1.20', 38)],
        [('0.06', 0), ('TVA', 5), ('5.5%', 9), ('1.08', 38)],
        [('TTL', 0), ('Net', 4), ('1.02', 38)],
      ]);
      final (evidence, ignored) = taxEvidence(lines);
      expect(evidence!.cents, 240);
      expect(ignored, {1, 2, 3, 4});
    });

    test('tva table row proves its ttc', () {
      final lines = priced([
        [('PEINTURE', 0), ('7,35', 38)],
        [('B', 0), ('20,00%', 2), ('6,13', 20), ('1,22', 28), ('7,35', 38)],
      ]);
      final (evidence, ignored) = taxEvidence(lines);
      expect(evidence!.cents, 735);
      expect(ignored, {1});
    });

    test('rate shaped row without lexicon is a tax row', () {
      final lines = priced([
        [('1', 0), ('29.99', 10), ('29.99', 30), ('A', 38)],
        [('A', 0), ('20.00', 4), ('24.99', 20), ('5.00', 38)],
      ]);
      final (evidence, ignored) = taxEvidence(lines);
      expect(evidence!.cents, 2999);
      expect(ignored, {1});
    });

    test('item matching the rate is not taken as ht', () {
      final lines = priced([
        [('BIERE', 0), ('5.00', 38)],
        [('TVA', 0), ('20%', 4), ('1.00', 38)],
        [('TOTAL', 0), ('6.00', 38)],
      ]);
      final (evidence, ignored) = taxEvidence(lines);
      expect(evidence, isNull);
      expect(ignored, isEmpty);
    });

    test('tva amount only without partner gives nothing', () {
      final lines = priced([
        [('PAIN', 0), ('2.50', 38)],
        [('Dont', 0), ('TVA', 5), ('0.13', 38)],
      ]);
      final (evidence, ignored) = taxEvidence(lines);
      expect(evidence, isNull);
      expect(ignored, isEmpty);
    });
  });

  group('payment change evidence', () {
    test('cash minus change', () {
      final lines = priced([
        [('PEINTURE', 0), ('7,35', 38)],
        [('ESPECES', 0), ('10,00', 38)],
        [('A', 0), ('RENDRE', 2), ('2,65', 38)],
      ]);
      final evidence = paymentChangeEvidence(lines)!;
      expect(evidence.cents, 735);
      expect(evidence.source, EvidenceSource.paymentChange);
      expect(evidence.cutoffRank, 1);
    });

    test('change line naming cash is not a payment', () {
      final lines = priced([
        [('SOUPE', 0), ('7,98', 38)],
        [('Espèces', 0), ('20,00', 38)],
        [('Rendu', 0), ('Espèces', 6), ('4,04', 38)],
      ]);
      expect(paymentChangeEvidence(lines)!.cents, 1596);
    });

    test('largest payment before the change is the cash given', () {
      final lines = priced([
        [('PDJ', 0), ('2.40', 38)],
        [('Especes', 0), ('3.00', 38)],
        [('Reglement', 0), ('2.40', 38)],
        [('A', 0), ('Rendre', 2), ('0.60', 38)],
      ]);
      expect(paymentChangeEvidence(lines)!.cents, 240);
    });

    test('negative change amount', () {
      final lines = priced([
        [('SAUCISSON', 0), ('4.79', 38)],
        [('ESPECES', 0), ('EUR', 8), ('5.00', 38)],
        [('Votre', 0), ('Monnaie', 6), ('-0.21', 37)],
      ]);
      expect(paymentChangeEvidence(lines)!.cents, 479);
    });

    test('no change line gives nothing', () {
      final lines = priced([
        [('PAIN', 0), ('2.50', 38)],
        [('ESPECES', 0), ('2.50', 38)],
      ]);
      expect(paymentChangeEvidence(lines), isNull);
    });
  });

  group('summary discounts', () {
    test('single discount recapped with total word', () {
      final lines = priced([
        [('LIT', 0), ('55,00', 38)],
        [('Nouveau', 0), ('prix', 8), ('49,90', 14), ('-5,10', 37)],
        [('SOUS', 0), ('TOTAL', 5), ('66,37', 38)],
        [('REMISE', 0), ('TOTALE', 7), ('-5,10', 37)],
        [('TOTAL', 0), ('61,27', 38)],
      ]);
      expect(summaryDiscountRanks(lines), {3});
    });

    test('two discounts recapped by their sum', () {
      final lines = priced([
        [('OEUFS', 0), ('6,20', 38)],
        [('50', 0), ('%', 3), ('PAQUES', 5), ('-1,55', 37)],
        [('50', 0), ('%', 3), ('PAQUES', 5), ('-1,55', 37)],
        [('REMISE', 0), ('TTALE', 7), ('-3,10', 37)],
        [('TOTAL', 0), ('3,10', 38)],
      ]);
      expect(summaryDiscountRanks(lines), {3});
    });

    test('identical real discounts are not summaries', () {
      final lines = priced([
        [('OEUFS', 0), ('6,20', 38)],
        [('50', 0), ('%', 3), ('PAQUES', 5), ('-1,55', 37)],
        [('50', 0), ('%', 3), ('PAQUES', 5), ('-1,55', 37)],
        [('TOTAL', 0), ('3,10', 38)],
      ]);
      expect(summaryDiscountRanks(lines), isEmpty);
    });

    test('total before discounts line is never a real discount', () {
      final lines = priced([
        [('OREILLER', 0), ('11,90', 38)],
        [('Remise', 0), ('Immédiate', 7), ('11,90', 38)],
        [('TOTAL', 0), ('AVANT', 6), ('REMISES', 12), ('41,29', 38)],
        [('TOTAL', 0), ('REMISE', 6), ('IMMEDIATE', 13), ('11,90', 38)],
        [('TOTAL', 0), ('DES', 6), ('AVANTAGES', 10), ('11,90', 38)],
        [('TOTAL', 0), ('A', 6), ('PAYER', 8), ('29,39', 38)],
      ]);
      expect(summaryDiscountRanks(lines), {3});
    });
  });

  group('reference ranks', () {
    test('section totals before the final total are not references', () {
      final lines = priced([
        [('PAIN', 0), ('0,99', 38)],
        [('TOTAL', 0), ('ALIMENTAIRE', 6), ('0,99', 38)],
        [('SAVON', 0), ('2,00', 38)],
        [('TOTAL', 0), ('HYGIENE', 6), ('2,00', 38)],
        [('TOTAL', 0), ('A', 6), ('PAYER', 8), ('2,99', 38)],
        [('CB', 0), ('2,99', 38)],
      ]);
      expect(referenceRanks(lines), {4, 5});
    });

    test('subtotal before a discount and ht lines are never references', () {
      final lines = priced([
        [('CAFE', 0), ('4,35', 38)],
        [('S/TOT', 0), ('18.47', 38)],
        [('SUB', 0), ('ORANGE', 4), ('-14.12', 37)],
        [('Total', 0), ('HT', 6), ('3.95', 38)],
        [('TOTAL', 0), ('4,35', 38)],
      ]);
      expect(referenceRanks(lines), {4});
    });

    test('without any total line every rank is eligible', () {
      final lines = priced([
        [('CAFE', 0), ('4,35', 38)],
        [('4,35', 38)],
      ]);
      expect(referenceRanks(lines), {0, 1});
    });

    test('subtotal without following discount is a reference', () {
      final lines = priced([
        [('BURGER', 0), ('8,95', 38)],
        [('SUBTOTAL', 0), ('8,95', 38)],
        [('TAX', 0), ('0,74', 38)],
        [('TOTAL', 0), ('9,69', 38)],
      ]);
      expect(referenceRanks(lines), {1, 3});
    });

    test('total printed after the payment is not the final total', () {
      final lines = priced([
        [('LAIT', 0), ('2,00', 38)],
        [('Total', 0), ('19', 6), ('articles', 9), ('2,00', 38)],
        [('CB', 0), ('2,00', 38)],
        [('Total', 0), ('Bon', 6), ('immediat', 10), ('3,72', 38)],
      ]);
      expect(lastTotalRank(lines), 1);
      expect(referenceRanks(lines), contains(1));
    });

    test('intermediate total followed only by taxes is eligible', () {
      final lines = priced([
        [('TACO', 0), ('4,95', 38)],
        [('Net', 0), ('Total', 4), ('4,95', 38)],
        [('Sales', 0), ('Tax', 6), ('0,52', 38)],
        [('TOTAL', 0), ('5,47', 38)],
      ]);
      expect(referenceRanks(lines), {1, 3});
    });

    test('recap line of the same amount does not block the subtotal', () {
      final lines = priced([
        [('ICED', 0), ('TEA', 5), ('4.50', 38)],
        [('BRANZINO', 0), ('40.00', 38)],
        [('FOOD', 0), ('44.50', 38)],
        [('SUB-TOTAL', 0), ('44.50', 38)],
        [('TAX', 0), ('3.95', 38)],
        [('TOTAL', 0), ('48.45', 38)],
      ]);
      expect(referenceRanks(lines), contains(3));
    });
  });

  group('section totals', () {
    test('bare line equal to the running sum is a section total', () {
      final lines = priced([
        [('POUDRE', 0), ('1.64', 38)],
        [('YAOURT', 0), ('1.30', 38)],
        [('RIZ', 0), ('1.60', 38)],
        [('ALINENTAIRE', 0), ('4.54', 38)],
        [('SAVON', 0), ('2.07', 38)],
        [('TOTAL', 0), ('BEAUTE', 6), ('2.07', 38)],
        [('TOTAL', 0), ('A', 6), ('PAYER', 8), ('6.61', 38)],
      ]);
      expect(sectionTotals(lines), [3, 5]);
    });

    test('single item before a bare line is not a section', () {
      final lines = priced([
        [('CAFE', 0), ('2.00', 38)],
        [('2.00', 38)],
        [('TOTAL', 0), ('4.00', 38)],
      ]);
      expect(sectionTotals(lines), isEmpty);
    });

    test('final total alone is not a section', () {
      final lines = priced([
        [('KIT', 0), ('9.90', 38)],
        [('Total', 0), ('Non', 6), ('Alimentaire', 10), ('9.90', 38)],
        [('Cartes', 0), ('Bancaires', 7), ('9.90', 38)],
      ]);
      expect(sectionTotals(lines), isEmpty);
    });

    test('sections sum is an evidence when they cover every item', () {
      final lines = priced([
        [('PURE', 0), ('7,05', 38)],
        [('KIT', 0), ('5,50', 38)],
        [('Total', 0), ('Soins', 6), ('12,55', 38)],
        [('CRF', 0), ('KIT', 4), ('9.90', 38)],
        [('Total', 0), ('Non', 6), ('Alimentaire', 10), ('9.90', 38)],
        [('Cartes', 0), ('Bancaires', 7), ('22,45', 38)],
      ]);
      final result = constraints(lines);
      final sections = [
        for (final e in result.evidences)
          if (e.source == EvidenceSource.sections) e,
      ];
      expect([for (final e in sections) e.cents], [2245]);
      expect(sections.first.cutoffRank, 4);
      expect(result.softIgnore, {2, 4});
    });

    test('no sections evidence when items follow the last section', () {
      final lines = priced([
        [('PURE', 0), ('7,05', 38)],
        [('KIT', 0), ('5,50', 38)],
        [('Total', 0), ('Soins', 6), ('12,55', 38)],
        [('CRF', 0), ('KIT', 4), ('9.90', 38)],
        [('Total', 0), ('Non', 6), ('Alimentaire', 10), ('9.90', 38)],
        [('BONBON', 0), ('1.00', 38)],
        [('TOTAL', 0), ('A', 6), ('PAYER', 8), ('23,45', 38)],
      ]);
      final result = constraints(lines);
      expect(
        result.evidences.where((e) => e.source == EvidenceSource.sections),
        isEmpty,
      );
    });
  });

  group('constraints', () {
    test('final total line is an evidence', () {
      final lines = priced([
        [('CLOU', 0), ('32,17', 38)],
        [("TO'AL", 0), ('Euro', 6), ('32.17', 38)],
      ]);
      final result = constraints(lines);
      final totalLine = result.evidences.firstWhere(
        (e) => e.source == EvidenceSource.totalLine,
      );
      expect(totalLine.cents, 3217);
      expect(totalLine.lineRank, 1);
    });

    test('forced ignore merges tax and summary ranks', () {
      final lines = priced([
        [('CAFE', 0), ('4.50', 38)],
        [('REMISE', 0), ('-0.50', 37)],
        [('REMISE', 0), ('TOTALE', 7), ('-0.50', 37)],
        [('TOTAL', 0), ('4.00', 38)],
        [('TVA', 0), ('10%', 4), ('0.36', 38)],
        [('HT', 0), ('3.64', 38)],
      ]);
      final result = constraints(lines);
      expect(result.forcedIgnore, {2, 4, 5});
      expect(
        {for (final e in result.evidences) e.source},
        {EvidenceSource.totalLine, EvidenceSource.tax},
      );
    });

    test('item priced like a rate is not a tax row', () {
      final lines = priced([
        [('KIT', 0), ('5,50', 38)],
        [('BOUGIE', 0), ('20,00', 38)],
        [('TOTAL', 0), ('25,50', 38)],
      ]);
      expect(constraints(lines).forcedIgnore, isEmpty);
    });

    test('tax lexicon line is forced ignore even without a partner', () {
      final lines = priced([
        [('BURGER', 0), ('8,95', 38)],
        [('TAX', 0), ('0,74', 38)],
        [('TOTAL', 0), ('9,69', 38)],
      ]);
      expect(constraints(lines).forcedIgnore, {1});
    });

    test('tax inclusive total line stays a reference', () {
      final lines = priced([
        [('CAFE', 0), ('2,00', 38)],
        [('TOTAL', 0), ('TVA', 6), ('INCL', 10), ('2,00', 38)],
      ]);
      final result = constraints(lines);
      expect(result.forcedIgnore, isEmpty);
      expect(result.referenceRanks, contains(1));
    });
  });
}
