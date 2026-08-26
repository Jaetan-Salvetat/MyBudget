/// Le tagger de rôles : quatorze rôles, toutes les lignes du ticket.
///
/// Il *désigne* la ligne, il ne lit pas le champ. L'enseigne échouait à la
/// sélection (`lines[0]` est souvent un slogan ou une adresse), la date à la
/// lecture : le modèle règle la première, le parsing garde la seconde.
///
/// Miroir de `ml/scan/research/reference/header_ml.py` et `labels_ml.py`.
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
  'tax',
  'payment',
  'change',
  'summary',
  'header',
  'footer',
  'noise',
];

const int roleStore = 0;
const int roleDateLine = 1;
const int roleItemLabel = 3;

/// En-dessous, le modèle hésite : mieux vaut pas d'enseigne du tout qu'une
/// ligne prise au hasard.
/// Seuil de désignation d'une ligne pour un rôle. Pour le rattachement de
/// libellé, 0,90 est la valeur calibrée par `bench.label_threshold` ; elle
/// suit la précision du tagger et se rejoue à chaque réentraînement.
const double minRoleProbability = 0.90;

/// Mesuré sur le corpus annoté : 96 % des libellés sont exactement une ligne
/// au-dessus de leur prix (686 sur 717). Ratisser plus large ne récupère
/// qu'une poignée de cas et rattache surtout du bruit.
const int maxLabelLookback = 1;
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

/// Donne à chaque article le libellé que le tagger lui désigne.
///
/// Les règles cherchent le libellé sur la ligne du prix ; quand le prix est
/// imprimé seul — pesée, quantité, code-barres — elles ramassent ce qui
/// traînait autour (« 0,792 kg 2,65 €/kg » au lieu de « POIRE CONFERENCE »).
///
/// **La décision revient au modèle, pas à un lexique.** Demander « ce libellé
/// est-il faible ? » et répondre par une liste de mots non nommants (EUR, kg,
/// Art, Montant…) est sans fin : chaque enseigne en apporte un nouveau. La
/// question posée ici est « où est le libellé de cet article ? », et le
/// corpus l'a annotée.
///
/// Les lignes désignées sont consommées dans l'ordre des articles, chacune
/// une seule fois : deux articles ne partagent pas un nom.
List<ExtractedItem> relabel(
  List<ExtractedItem> items,
  List<PhysicalLine> lines,
  List<List<double>> probabilities,
) {
  if (probabilities.isEmpty) return items;
  final used = <int>{};
  for (final item in items) {
    final source = item.lineIndex;
    if (source == null) continue;
    for (var offset = 1; offset <= maxLabelLookback; offset++) {
      final candidate = source - offset;
      if (candidate < 0) break;
      if (used.contains(candidate) ||
          probabilities[candidate][roleItemLabel] < minRoleProbability) {
        continue;
      }
      final label = plausibleLabel(lines[candidate].text);
      if (label != null) {
        item.name = cleanName(label);
        used.add(candidate);
        break;
      }
    }
  }
  return items;
}
