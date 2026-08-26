/// Le tagger de rôles : neuf classes, toutes les lignes du ticket.
///
/// Il *désigne* la ligne, il ne lit pas le champ. L'enseigne échouait à la
/// sélection (`lines[0]` est souvent un slogan ou une adresse), la date à la
/// lecture : le modèle règle la première, le parsing garde la seconde.
///
/// Le corpus annote quatorze rôles, le modèle n'en prédit que neuf : six
/// d'entre eux — tax, change, summary, header, footer, noise — ne sont lus
/// par aucun consommateur, et les distinguer coûtait 41 % des erreurs du
/// tagger sans rien rapporter. Ils sont fondus dans `noise`.
///
/// Miroir de `ml/scan/research/reference/header_ml.py` et `line_labels.py`.
library;

import 'classifier.dart';
import 'line_features_all.dart';
import 'lines.dart';
import 'structure.dart';

/// Ordre des rôles, contrat partagé avec `annotate/schema.py`. Un décalage
/// ici ferait désigner silencieusement la mauvaise ligne : `RoleTagger`
/// vérifie la liste au chargement plutôt que de faire confiance.
const List<String> roleNames = [
  'store',
  'date_line',
  'item',
  'item_label',
  'discount',
  'subtotal',
  'total',
  'payment',
  'noise',
];

const int roleStore = 0;
const int roleDateLine = 1;

/// En-dessous, le modèle hésite : mieux vaut pas d'enseigne ni de date du
/// tout qu'une ligne prise au hasard. Le rattachement du libellé ne passe
/// plus par ce seuil — il a son propre modèle (`label_link.dart`).
const double minRoleProbability = 0.5;

class RoleTagger {
  RoleTagger(this._model) {
    if (_model.classCount != roleNames.length) {
      throw StateError(
        'Tagger à ${_model.classCount} rôles, ${roleNames.length} attendus',
      );
    }
  }

  final LineClassifier _model;

  /// Probabilité de chaque rôle pour chaque ligne, dans l'ordre du ticket.
  List<List<double>> probabilities(List<PhysicalLine> lines) =>
      _model.predictProbaAll(featurizeAll(lines));

  /// Le rôle le plus probable de chaque ligne — l'argmax, sans seuil : la
  /// décision se juge au checksum, pas à une confiance choisie à la main.
  List<String> roles(List<PhysicalLine> lines) => [
    for (final row in probabilities(lines)) roleNames[argmax(row)],
  ];
}

/// La ligne la plus probable pour ce rôle — un ticket n'en a qu'une.
int? bestLineFor(List<List<double>> probabilities, int role) {
  if (probabilities.isEmpty) return null;
  var best = 0;
  for (var index = 1; index < probabilities.length; index++) {
    if (probabilities[index][role] > probabilities[best][role]) best = index;
  }
  return probabilities[best][role] > minRoleProbability ? best : null;
}

String? storeOf(List<PhysicalLine> lines, List<List<double>> probabilities) {
  final index = bestLineFor(probabilities, roleStore);
  return index == null ? null : lines[index].text;
}

/// La date lue sur la ligne désignée ; à défaut, sur tout le ticket — le
/// tagger peut se tromper de ligne, il ne doit pas faire perdre une date que
/// les règles savaient lire.
String? dateOf(List<PhysicalLine> lines, List<List<double>> probabilities) {
  final index = bestLineFor(probabilities, roleDateLine);
  if (index != null) {
    final found = findDate([lines[index]]);
    if (found != null) return found;
  }
  return findDate(lines);
}
