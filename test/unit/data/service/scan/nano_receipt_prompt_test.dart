import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/constants/receipt_schema.dart';
import 'package:mybudget/data/service/scan/nano_receipt_prompt.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

import '../../../../helpers/receipt_line_factory.dart';

void main() {
  group('receiptTranscript', () {
    test('reprend les lignes du ticket dans l\'ordre', () {
      final transcript = receiptTranscript(
        receiptLinesOf([
          [('CARREFOUR', 0)],
          [('PAIN', 0), ('2,00', 20)],
          [('TOTAL', 0), ('2,00', 20)],
        ]),
      );

      expect(transcript, isNotNull);
      expect(transcript, startsWith('CARREFOUR'));
      expect(
        transcript!.indexOf('PAIN 2,00'),
        lessThan(transcript.indexOf('TOTAL')),
      );
    });

    test('un ticket trop long n\'est pas soumis au modèle', () {
      final rows = [
        for (var index = 0; index < 400; index++)
          [('ARTICLE$index', 0), ('2,00', 20)],
      ];

      expect(receiptTranscript(receiptLinesOf(rows)), isNull);
    });

    test('un ticket sans texte n\'est pas soumis au modèle', () {
      expect(receiptTranscript(const <PhysicalLine>[]), isNull);
    });

    test('la limite tient compte du seul texte du ticket', () {
      final rows = [
        for (var index = 0; index < 20; index++)
          [('ARTICLE$index', 0), ('2,00', 20)],
      ];

      expect(receiptTranscript(receiptLinesOf(rows)), isNotNull);
      expect(
        receiptText(receiptLinesOf(rows)).length,
        lessThan(ReceiptSchema.maxReceiptCharacters),
      );
    });
  });

  group('sectionPrompt', () {
    test('la tâche précède la transcription, séparées par un délimiteur', () {
      final prompt = sectionPrompt(storeSectionPrompt, 'CARREFOUR\nPAIN 2,00');

      expect(prompt, startsWith(storeSectionPrompt));
      expect(prompt, contains('## Transcription OCR'));
      expect(prompt, endsWith('CARREFOUR\nPAIN 2,00'));
    });

    test('chaque section demande une donnée et une seule', () {
      expect(storeSectionPrompt, contains('l\'enseigne'));
      expect(dateSectionPrompt, contains('la date d\'achat'));
      expect(totalSectionPrompt, contains('le total payé'));
      expect(itemsSectionPrompt, contains('les articles achetés'));
    });
  });
}
