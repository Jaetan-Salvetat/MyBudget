library;

import 'classifier.dart';
import 'line_features_all.dart';
import 'lines.dart';
import 'store_classifier.dart';
import 'store_gazetteer.dart';
import 'structure.dart';

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
const int roleItemIndex = 2;

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

  List<List<double>> probabilities(List<PhysicalLine> lines) =>
      _model.predictProbaAll(featurizeAll(lines));

  List<String> roles(List<PhysicalLine> lines) =>
      predictedRoles(probabilities(lines));
}

List<String> predictedRoles(List<List<double>> probabilities) => [
  for (final row in probabilities) roleNames[argmax(row)],
];

int? bestLineFor(List<List<double>> probabilities, int role) {
  if (probabilities.isEmpty) return null;
  var best = 0;
  for (var index = 1; index < probabilities.length; index++) {
    if (probabilities[index][role] > probabilities[best][role]) best = index;
  }
  return probabilities[best][role] > minRoleProbability ? best : null;
}

String? storeOf(
  List<PhysicalLine> lines,
  List<List<double>> probabilities, {
  Gazetteer? gazetteer,
  StoreClassifier? classifier,
}) {
  if (probabilities.isEmpty) return null;
  final known = classifier?.predict(lines);
  if (known != null) return known;
  final index = bestLineFor(probabilities, roleStore);
  if (index == null) return null;
  final text = lines[index].text;
  return gazetteer?.match(text) ?? text;
}

String? dateOf(List<PhysicalLine> lines, List<List<double>> probabilities) {
  final index = bestLineFor(probabilities, roleDateLine);
  if (index != null) {
    final found = findDate([lines[index]]);
    if (found != null) return found;
  }
  return findDate(lines);
}
