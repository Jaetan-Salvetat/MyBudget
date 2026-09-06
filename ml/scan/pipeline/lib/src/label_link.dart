library;

import 'classifier.dart';
import 'label_span.dart';
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

  List<int> offsets(List<PhysicalLine> lines) {
    final rows = featurizeAll(lines);
    if (rows.isEmpty) return const [];
    return [
      for (var index = 0; index < rows.length; index++)
        _model.predict(windowFeatures(rows, index)),
    ];
  }
}

List<ExtractedItem> relabel(
  List<ExtractedItem> items,
  List<PhysicalLine> lines,
  List<int> offsets,
  List<List<double>> probabilities,
) {
  if (offsets.isEmpty) return items;
  final used = <int>{};
  for (final item in items) {
    final source = item.lineIndex;
    if (source == null || source >= offsets.length) continue;
    final carrier = source - offsets[source];
    if (carrier < 0 ||
        carrier >= lines.length ||
        carrier >= probabilities.length) {
      continue;
    }
    final deported = carrier != source;
    if (deported && used.contains(carrier)) continue;
    final label = labelOf(lines[carrier], probabilities[carrier]);
    if (label == null) continue;
    item.name = label;
    if (deported) used.add(carrier);
  }
  return items;
}
