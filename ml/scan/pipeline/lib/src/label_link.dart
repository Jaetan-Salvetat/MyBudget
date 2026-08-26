/// Le modèle de lien : où est le libellé de cet article ?
///
/// Les règles cherchent le libellé sur la ligne du prix ; quand le prix est
/// imprimé seul — pesée, quantité, code-barres — elles ramassent ce qui
/// traînait autour (« 0,792 kg 2,65 €/kg » au lieu de « POIRE CONFERENCE »).
///
/// Le rattachement se décidait avec deux nombres choisis à la main : la ligne
/// juste au-dessus, si le tagger de rôles la disait `item_label` avec assez
/// de confiance. Or la distance dépend du ticket — chez une enseigne le prix
/// est sur la ligne du nom, chez une autre il vient après une pesée — et le
/// corpus annote déjà la réponse. Le modèle répond par une distance : 0 quand
/// le libellé est sur la ligne du prix, k quand il est k lignes au-dessus.
///
/// Miroir de `ml/scan/research/reference/labels_ml.py`.
library;

import 'classifier.dart';
import 'line_features_all.dart';
import 'lines.dart';
import 'structure.dart';

class LabelLinkModel {
  LabelLinkModel(this._model) {
    final expected = windowFeatureNames().length;
    if (_model.featureCount != expected) {
      throw StateError(
        'Modèle de lien à ${_model.featureCount} colonnes, $expected attendues',
      );
    }
  }

  final LineClassifier _model;

  /// Pour chaque ligne, la distance qui la sépare du libellé de l'article
  /// dont elle porte le prix — 0 quand ce libellé est sur elle-même.
  List<int> offsets(List<PhysicalLine> lines) {
    final rows = featurizeAll(lines);
    if (rows.isEmpty) return const [];
    return [
      for (var index = 0; index < rows.length; index++)
        _model.predict(windowFeatures(rows, index)),
    ];
  }
}

/// Donne à chaque article le libellé de la ligne que le modèle désigne.
///
/// Les lignes désignées sont consommées dans l'ordre des articles, chacune
/// une seule fois : deux articles ne partagent pas un nom.
List<ExtractedItem> relabel(
  List<ExtractedItem> items,
  List<PhysicalLine> lines,
  List<int> offsets,
) {
  if (offsets.isEmpty) return items;
  final used = <int>{};
  for (final item in items) {
    final source = item.lineIndex;
    if (source == null || source >= offsets.length) continue;
    final candidate = source - offsets[source];
    if (candidate == source || candidate < 0 || used.contains(candidate)) {
      continue;
    }
    final label = plausibleLabel(lines[candidate].text);
    if (label == null) continue;
    item.name = cleanName(label);
    used.add(candidate);
  }
  return items;
}
