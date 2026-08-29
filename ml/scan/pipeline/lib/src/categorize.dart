/// Catégorisation des articles d'un ticket : **chaque article se classe seul**.
///
/// La version précédente déduisait la classe du ticket de son enseigne, puis
/// donnait cette classe à tous ses articles. La taxonomie étant une taxonomie
/// de marchands, cela paraissait naturel — et cela rendait la catégorie d'un
/// article dépendante du magasin où il avait été lu : le même pain était
/// « boulangerie » ici et « supermarché » là. Le corpus d'entraînement portait
/// la même faute, et 10,7 % de ses lignes se contredisaient.
///
/// Il n'y a donc plus de décision à prendre ici : le modèle lit un libellé
/// normalisé, il rend une classe, elle est celle de l'article. Ce qui se joue
/// vraiment se joue dans le corpus (`ml/classifier/corpus/receipts/`), et se
/// mesure par `evaluation/receipts.py`.
///
/// La normalisation vit dans `normalize.dart`, miroir de
/// `ml/classifier/serving/normalize.py`.
library;

import 'normalize.dart';

/// Ce que le modèle dit d'une ligne : une catégorie et sa confiance.
typedef LinePrediction = ({String slug, double confidence});

/// Classe une ligne déjà normalisée.
/// Abstrait pour que le pipeline se teste sans modèle.
abstract interface class ReceiptLineClassifier {
  Future<LinePrediction> classify(String normalizedLine);
}

/// Donne sa catégorie à chaque libellé d'un ticket, dans l'ordre reçu.
class ReceiptCategorizer {
  final ReceiptLineClassifier _classifier;

  const ReceiptCategorizer(this._classifier);

  Future<List<LinePrediction>> categorize(List<String> itemNames) async => [
    for (final name in itemNames)
      await _classifier.classify(normalizeReceiptLine(name)),
  ];
}
