import 'package:mybudget/core/constants/receipt_schema.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

const String _role =
    '## Rôle\nTu lis la photo d\'un ticket de caisse français.\n\n';

const String _rules =
    '## Règles\n'
    'Ne rends que ce qui est imprimé, n\'invente rien.\n'
    'Un article : son libellé complet et son prix.\n'
    'Ignore sous-total, TVA, monnaie, paiement, fidélité, adresse, caisse, '
    'poids au kilo.\n'
    'Une remise n\'est pas un article : son montant va dans le discount de '
    'l\'article au-dessus.\n'
    'Somme des amount moins les discount = total.\n\n'
    '## Exemple\n'
    '{"store":"CARREFOUR CITY","date":"2017-02-24","total":4.15,'
    '"items":[{"name":"300G MOUSSAKA BARQ","amount":2.95,"discount":0},'
    '{"name":"CLEMENTINE","amount":1.20,"discount":0}]}';

const String _transcript = '\n\n## Transcription OCR, la photo fait foi\n';

const String storeSectionPrompt =
    '$_role'
    '## Tâche\nRends uniquement l\'enseigne imprimée en tête de ticket, '
    'recopiée telle quelle.\n\n'
    '## Exemple\n{"store":"CARREFOUR CITY"}';

const String dateSectionPrompt =
    '$_role'
    '## Tâche\nRends uniquement la date d\'achat imprimée sur le ticket.\n\n'
    '## Exemple\n{"date":"2017-02-24"}';

const String totalSectionPrompt =
    '$_role'
    '## Tâche\nRends uniquement le total payé imprimé en bas du ticket.\n\n'
    '## Exemple\n{"total":4.15}';

const String itemsSectionPrompt =
    '$_role'
    '## Tâche\nRends les articles achetés et le total payé.\n\n'
    '$_rules';

String receiptText(List<PhysicalLine> lines) =>
    mergedLines(lines).map((line) => line.text).join('\n');

/// La transcription OCR jointe à chaque section, ou `null` si elle est vide ou
/// trop longue pour la fenêtre du modèle.
String? receiptTranscript(List<PhysicalLine> lines) {
  if (lines.isEmpty) return null;

  final ticket = receiptText(lines);
  if (ticket.isEmpty) return null;
  if (ticket.length > ReceiptSchema.maxReceiptCharacters) return null;

  return ticket;
}

String sectionPrompt(String task, String transcript) =>
    '$task$_transcript$transcript';
