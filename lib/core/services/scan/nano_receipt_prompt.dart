import 'package:mybudget/core/constants/receipt_schema.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

const String _instructions =
    'Tu lis un ticket de caisse français rendu par un OCR, une ligne par '
    'ligne, de haut en bas.\n'
    'Rapporte uniquement ce qui est imprimé : n\'invente ni article, ni '
    'montant, ni date.\n'
    '- "store" : l\'enseigne en tête de ticket.\n'
    '- "date" : la date d\'achat, au format AAAA-MM-JJ.\n'
    '- "total" : le total payé imprimé en bas du ticket.\n'
    '- "items" : un élément par article acheté, avec son libellé et son prix.\n'
    'Écarte les lignes qui ne sont pas des articles : sous-total, TVA, rendu '
    'monnaie, moyen de paiement, points de fidélité, remerciements, adresse, '
    'numéro de caisse.\n'
    'Une ligne de remise ou de bon d\'achat ne devient pas un article : porte '
    'son montant dans le "discount" de l\'article qui la précède.\n'
    'Les prix sont en euros et la virgule sépare les décimales.\n'
    'La somme des "amount" moins les "discount" doit tomber sur le "total".\n\n'
    'Ticket :\n';

String receiptText(List<PhysicalLine> lines) =>
    mergedLines(lines).map((line) => line.text).join('\n');

String? nanoReceiptPrompt(List<PhysicalLine> lines) {
  if (lines.isEmpty) return null;

  final ticket = receiptText(lines);
  if (ticket.isEmpty) return null;
  if (ticket.length > ReceiptSchema.maxReceiptCharacters) return null;

  return '$_instructions$ticket';
}
