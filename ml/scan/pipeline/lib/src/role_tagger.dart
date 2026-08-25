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
const double minRoleProbability = 0.5;

/// Un libellé peut être imprimé jusqu'à trois lignes au-dessus de son prix.
const int maxLabelLookback = 3;
const int minNamingLetters = 3;

/// Ce qu'un ticket imprime à côté d'un prix sans que ça nomme quoi que ce
/// soit : devise, régime de taxe, code de TVA en fin de ligne.
const Set<String> nonNamingTokens = {
  'EUR', 'EURO', 'EUROS', 'USD', 'HT', 'TTC', 'TVA', 'A', 'B', 'C', 'D', 'X',
};

final RegExp _nonLetters = RegExp(r'[^A-Za-zÀ-ÿ]+');

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

/// Un libellé qui ne nomme rien : « EUR », « A », un code-barres seul. Le
/// prix était sur sa propre ligne et les règles ont ramassé ce qui traînait.
bool namesNothing(String name) {
  final words = name
      .replaceAll(_nonLetters, ' ')
      .toUpperCase()
      .split(' ')
      .where((word) => word.isNotEmpty && !nonNamingTokens.contains(word));
  return words.fold(0, (sum, word) => sum + word.length) < minNamingLetters;
}

/// Remplace les libellés qui ne nomment rien par la ligne `item_label` la
/// plus proche au-dessus, chacune ne servant qu'une fois — deux articles ne
/// partagent pas un nom.
///
/// Corrige, n'arbitre pas : un libellé déjà parlant n'est jamais écrasé. Le
/// tagger se trompe une fois sur six sur ce rôle, et le nom décide de la
/// catégorie donc de la ligne de budget.
List<ExtractedItem> relabel(
  List<ExtractedItem> items,
  List<PhysicalLine> lines,
  List<List<double>> probabilities,
) {
  if (probabilities.isEmpty) return items;
  final used = <int>{};
  for (final item in items) {
    final source = item.lineIndex;
    if (source == null || !namesNothing(item.name)) continue;
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
