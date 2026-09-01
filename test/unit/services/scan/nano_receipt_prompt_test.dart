import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/constants/receipt_schema.dart';
import 'package:mybudget/core/services/scan/nano_receipt_prompt.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

import '../../../helpers/receipt_line_factory.dart';

void main() {
  group('nanoReceiptPrompt', () {
    test('reprend les lignes du ticket dans l\'ordre', () {
      final prompt = nanoReceiptPrompt(
        receiptLinesOf([
          [('CARREFOUR', 0)],
          [('PAIN', 0), ('2,00', 20)],
          [('TOTAL', 0), ('2,00', 20)],
        ]),
      );

      expect(prompt, isNotNull);
      final ticket = prompt!.substring(prompt.indexOf('CARREFOUR'));
      expect(ticket, contains('CARREFOUR'));
      expect(ticket.indexOf('PAIN 2,00'), lessThan(ticket.indexOf('TOTAL')));
    });

    test('un ticket trop long n\'est pas soumis au modèle', () {
      final rows = [
        for (var index = 0; index < 400; index++)
          [('ARTICLE$index', 0), ('2,00', 20)],
      ];

      expect(nanoReceiptPrompt(receiptLinesOf(rows)), isNull);
    });

    test('un ticket sans texte n\'est pas soumis au modèle', () {
      expect(nanoReceiptPrompt(const <PhysicalLine>[]), isNull);
    });

    test('la limite tient compte du seul texte du ticket', () {
      final rows = [
        for (var index = 0; index < 20; index++)
          [('ARTICLE$index', 0), ('2,00', 20)],
      ];
      final prompt = nanoReceiptPrompt(receiptLinesOf(rows));

      expect(prompt, isNotNull);
      expect(receiptText(receiptLinesOf(rows)).length,
          lessThan(ReceiptSchema.maxReceiptCharacters));
    });
  });
}
