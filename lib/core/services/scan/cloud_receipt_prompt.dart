import 'package:mybudget/core/constants/receipt_schema.dart';

const String cloudReceiptPrompt =
    'Tu lis la photo d\'un ticket de caisse français.\n'
    'Rapporte uniquement ce qui est imprimé : n\'invente ni article, ni '
    'montant, ni date.\n'
    '- "${ReceiptSchema.storeKey}" : l\'enseigne en tête de ticket.\n'
    '- "${ReceiptSchema.dateKey}" : la date d\'achat, au format AAAA-MM-JJ.\n'
    '- "${ReceiptSchema.totalKey}" : le total payé imprimé en bas du ticket.\n'
    '- "${ReceiptSchema.itemsKey}" : un élément par article acheté, avec son '
    'libellé et son prix.\n'
    'Écarte les lignes qui ne sont pas des articles : sous-total, TVA, rendu '
    'monnaie, moyen de paiement, points de fidélité, remerciements, adresse, '
    'numéro de caisse.\n'
    'Une ligne de remise ou de bon d\'achat ne devient pas un article : porte '
    'son montant dans le "${ReceiptSchema.itemDiscountKey}" de l\'article qui '
    'la précède.\n'
    'Un article acheté en quantité porte son prix total, avant remise.\n'
    'Les prix sont en euros et la virgule sépare les décimales.\n'
    'La somme des "${ReceiptSchema.itemAmountKey}" moins les '
    '"${ReceiptSchema.itemDiscountKey}" doit tomber sur le '
    '"${ReceiptSchema.totalKey}".';

const Map<String, dynamic> cloudReceiptSchema = {
  'type': 'object',
  'properties': {
    ReceiptSchema.storeKey: {
      'type': ['string', 'null'],
    },
    ReceiptSchema.dateKey: {
      'type': ['string', 'null'],
    },
    ReceiptSchema.totalKey: {
      'type': ['number', 'null'],
    },
    ReceiptSchema.itemsKey: {
      'type': 'array',
      'items': {
        'type': 'object',
        'properties': {
          ReceiptSchema.itemNameKey: {'type': 'string'},
          ReceiptSchema.itemAmountKey: {'type': 'number'},
          ReceiptSchema.itemDiscountKey: {'type': 'number'},
        },
        'required': [
          ReceiptSchema.itemNameKey,
          ReceiptSchema.itemAmountKey,
          ReceiptSchema.itemDiscountKey,
        ],
        'additionalProperties': false,
      },
    },
  },
  'required': [
    ReceiptSchema.storeKey,
    ReceiptSchema.dateKey,
    ReceiptSchema.totalKey,
    ReceiptSchema.itemsKey,
  ],
  'additionalProperties': false,
};
