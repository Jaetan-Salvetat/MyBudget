/// Catégorisation d'un ticket structuré : normalisation des libellés pour le
/// modèle quick-add, puis décision enseigne / articles.
///
/// Miroir exact de `ml/classifier/serving/cascade.py` ; la normalisation vit
/// dans `normalize.dart`. La cascade est mesurée par
/// `receipts/evaluate.py --cascade`.
library;

import 'normalize.dart';

/// Ce que le modèle dit d'une ligne : une catégorie et sa confiance.
typedef LinePrediction = ({String slug, double confidence});

/// Un ticket catégorisé : sa classe et celle de chaque article, dans l'ordre
/// des libellés reçus.
typedef CategorizedReceipt = ({LinePrediction ticket, List<String> itemSlugs});

/// Classe une ligne déjà normalisée (en-tête d'enseigne ou libellé).
/// Abstrait pour que la décision se teste sans modèle.
abstract interface class ReceiptLineClassifier {
  Future<LinePrediction> classify(String normalizedLine);
}

/// La décision de catégorie d'un ticket scanné.
///
/// La taxonomie est une taxonomie de marchands : la classe naturelle d'un
/// article est celle de son enseigne. Le modèle est appelé sur l'en-tête puis
/// sur chaque libellé ; les prédictions d'articles ne servent qu'à deux
/// choses : remplacer l'enseigne quand elle est illisible ou incertaine (vote
/// pondéré par la confiance), et sortir un article de la classe du ticket
/// quand il appartient à une famille budgétaire distincte avec assez de
/// confiance — seulement dans une enseigne alimentaire, la seule qui vende
/// de tout.
class ReceiptCategorizer {
  static const double storeMinConfidence = 0.9;
  static const double itemOverrideMinConfidence = 0.8;
  static const String _generalistPrefix = 'alimentation.';
  static const String _fallbackSlug = 'divers.autre';

  static const Set<String> overrideFamilies = {
    'shopping.vetements',
    'shopping.electronique',
    'shopping.mobilier_deco',
    'divers.animaux',
    'divers.tabac_jeux',
    'divers.cadeau_offert',
    'loisirs.livre_presse',
    'loisirs.musique',
    'loisirs.jeux_video',
    'loisirs.sport',
    'sante_beaute.pharmacie',
    'sante_beaute.esthetique',
    'famille_education.fournitures',
    'famille_education.activites_enfants',
    'logement.travaux',
    'transport.essence',
    'transport.entretien_vehicule',
  };

  final ReceiptLineClassifier _classifier;

  const ReceiptCategorizer(this._classifier);

  /// [store] est l'en-tête lu sur le ticket, null quand il est illisible.
  Future<CategorizedReceipt> categorize({
    required String? store,
    required List<String> itemNames,
  }) async {
    final storePrediction = store == null || store.trim().isEmpty
        ? null
        : await _classifier.classify(normalizeReceiptLine(store));
    final itemPredictions = <LinePrediction>[
      for (final name in itemNames)
        await _classifier.classify(normalizeReceiptLine(name)),
    ];
    final ticket = ticketCategory(storePrediction, itemPredictions);
    return (
      ticket: ticket,
      itemSlugs: [
        for (final item in itemPredictions) itemCategory(ticket, item),
      ],
    );
  }

  /// L'enseigne si elle est lisible et sûre, sinon le vote des articles.
  static LinePrediction ticketCategory(
    LinePrediction? store,
    List<LinePrediction> items,
  ) {
    if (store != null && store.confidence >= storeMinConfidence) return store;
    if (items.isEmpty) return store ?? (slug: _fallbackSlug, confidence: 0.0);

    final votes = <String, double>{};
    for (final item in items) {
      votes.update(
        item.slug,
        (weight) => weight + item.confidence,
        ifAbsent: () => item.confidence,
      );
    }
    final winner = votes.entries.reduce(
      (best, entry) => entry.value > best.value ? entry : best,
    );
    return (slug: winner.key, confidence: winner.value / items.length);
  }

  static String itemCategory(LinePrediction ticket, LinePrediction item) {
    final generalist = ticket.slug.startsWith(_generalistPrefix);
    if (generalist &&
        overrideFamilies.contains(item.slug) &&
        item.confidence >= itemOverrideMinConfidence) {
      return item.slug;
    }
    return ticket.slug;
  }
}
