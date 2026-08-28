/// Le libellé d'un article, décidé mot à mot sur la ligne qui le porte.
///
/// Le modèle de lien désigne la ligne ; ce modèle-ci dit quels mots de cette
/// ligne composent le nom. Il remplace la coupe de colonne des règles et le
/// nettoyage par expressions régulières : un ticket imprime plusieurs
/// colonnes de nombres, et une coupe unique laisse passer le code article à
/// gauche comme la quantité à droite.
///
/// Le décodage impose ce que le libellé est par nature — un intervalle
/// contigu de mots portant des lettres — et rien de plus. Aucun seuil :
/// l'intervalle retenu est celui dont la somme des log-odds est la plus
/// forte, et un mot n'y entre que s'il rapporte plus qu'il ne coûte.
///
/// Miroir de `ml/scan/research/reference/spans_ml.py`.
library;

import 'dart:math' as math;

import 'classifier.dart';
import 'lines.dart';
import 'word_features.dart';

/// Un libellé nomme un article : il porte des lettres. Deux, pour écarter
/// l'initiale isolée qu'un OCR laisse traîner à côté d'un nombre.
const int minLabelLetters = 2;
const double _probabilityClip = 1e-6;

final RegExp _labelLetter = RegExp(r'\p{L}', unicode: true);

class LabelSpan {
  const LabelSpan(this.start, this.end);

  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is LabelSpan && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'LabelSpan($start, $end)';
}

class LabelSpanModel {
  LabelSpanModel(this._model) {
    if (_model.featureCount != wordFeatureNames.length) {
      throw StateError(
        'Tagger de spans à ${_model.featureCount} colonnes, '
        '${wordFeatureNames.length} attendues',
      );
    }
  }

  final LineClassifier _model;

  /// Pour chaque mot de chaque ligne, la probabilité qu'il appartienne au
  /// libellé d'un article.
  List<List<double>> probabilities(List<PhysicalLine> lines) {
    final rows = featurizeWords(lines);
    return [
      for (final line in rows)
        [for (final vector in line) _model.predictProba(vector)[1]],
    ];
  }
}

double _logit(double probability) {
  final clipped = math.min(
    math.max(probability, _probabilityClip),
    1 - _probabilityClip,
  );
  return math.log(clipped / (1 - clipped));
}

int _letters(List<String> texts, int start, int end) {
  var count = 0;
  for (var index = start; index < end; index++) {
    count += _labelLetter.allMatches(texts[index]).length;
  }
  return count;
}

/// L'intervalle de log-odds maximale parmi ceux qui portent des lettres, ou
/// null si la ligne n'en porte aucune.
LabelSpan? bestSpan(List<String> texts, List<double> probabilities) {
  if (texts.isEmpty) return null;
  final odds = [for (final probability in probabilities) _logit(probability)];
  LabelSpan? span;
  double? bestScore;
  var bestLength = 0;
  var bestStart = 0;
  for (var start = 0; start < texts.length; start++) {
    var running = 0.0;
    for (var end = start + 1; end <= texts.length; end++) {
      running += odds[end - 1];
      if (_letters(texts, start, end) < minLabelLetters) continue;
      final length = end - start;
      final better =
          bestScore == null ||
          running > bestScore ||
          (running == bestScore &&
              (length > bestLength ||
                  (length == bestLength && start < bestStart)));
      if (better) {
        bestScore = running;
        bestLength = length;
        bestStart = start;
        span = LabelSpan(start, end);
      }
    }
  }
  return span;
}

String spanText(List<String> texts, LabelSpan span) =>
    texts.sublist(span.start, span.end).join(' ').trim();

/// Le libellé que porte cette ligne, ou null si elle n'en porte pas.
String? labelOf(PhysicalLine line, List<double> probabilities) {
  final texts = [for (final word in line.words) word.text];
  final span = bestSpan(texts, probabilities);
  return span == null ? null : spanText(texts, span);
}
