/// Fusion de deux passes OCR sur la même image, ligne physique à ligne.
/// Portage de référence de `research/reference/fuse_passes.py`.
///
/// Les deux passes (brute, prétraitée) abîment des lignes différentes : l'une
/// colle une lettre au prix, l'autre saute un article. Alignées par position
/// verticale, elles se complètent : une ligne non chiffrée dans la passe
/// principale prend la lecture de l'autre, une ligne absente est insérée, un
/// montant différent devient une alternative que le décodeur sous contrainte
/// arbitre. Rien n'est inventé : chaque montant vient d'une passe OCR.
library;

import 'lines.dart';
import 'structure.dart';

const double alignmentToleranceRatio = 0.6;

class FusedPass {
  const FusedPass({required this.lines, this.alternatives = const {}});

  final List<PhysicalLine> lines;

  /// Index de ligne fusionnée → montant alternatif en centimes.
  final Map<int, int> alternatives;
}

class _Placed {
  const _Placed(this.line, this.centerY, [this.alternativeCents]);

  final PhysicalLine line;
  final double centerY;
  final int? alternativeCents;
}

double _centerY(PhysicalLine line) {
  final centers = [for (final word in line.words) word.centerY]..sort();
  return centers[centers.length ~/ 2];
}

double _medianHeight(List<PhysicalLine> lines) {
  final heights = [
    for (final line in lines)
      for (final word in line.words) word.height,
  ]..sort();
  return heights.isEmpty ? 1.0 : heights[heights.length ~/ 2];
}

int? _cents(PhysicalLine line) {
  final priced = rightmostPrice(line);
  return priced == null ? null : (priced.price * 100).round();
}

int _priceCount(PhysicalLine line) =>
    line.words.where((word) => parsePrice(word.text) != null).length;

(Map<int, List<int>>, List<int>) _matchSecondary(
  List<PhysicalLine> primary,
  List<PhysicalLine> secondary,
  double tolerance,
) {
  final matches = {for (var i = 0; i < primary.length; i++) i: <int>[]};
  final unmatched = <int>[];
  final centers = [for (final line in primary) _centerY(line)];
  for (final (secondaryIndex, line) in secondary.indexed) {
    final center = _centerY(line);
    int? nearest;
    for (var i = 0; i < primary.length; i++) {
      if (nearest == null ||
          (centers[i] - center).abs() < (centers[nearest] - center).abs()) {
        nearest = i;
      }
    }
    if (nearest == null || (centers[nearest] - center).abs() > tolerance) {
      unmatched.add(secondaryIndex);
    } else {
      matches[nearest]!.add(secondaryIndex);
    }
  }
  return (matches, unmatched);
}

List<_Placed> _placeSingle(PhysicalLine primary, PhysicalLine match) {
  final primaryCents = _cents(primary);
  final matchCents = _cents(match);
  if (primaryCents == null && matchCents != null) {
    return [_Placed(match, _centerY(match))];
  }
  final alternative =
      primaryCents != null && matchCents != null && matchCents != primaryCents
      ? matchCents
      : null;
  return [_Placed(primary, _centerY(primary), alternative)];
}

List<_Placed> _placeSeveral(PhysicalLine primary, List<PhysicalLine> matches) {
  if (_priceCount(primary) >= 2) {
    return [for (final match in matches) _Placed(match, _centerY(match))];
  }
  final primaryCents = _cents(primary);
  return [
    _Placed(primary, _centerY(primary)),
    for (final match in matches)
      if (_cents(match) case final cents? when cents != primaryCents)
        _Placed(match, _centerY(match)),
  ];
}

FusedPass fusePasses(List<PhysicalLine> primary, List<PhysicalLine> secondary) {
  final tolerance = alignmentToleranceRatio * _medianHeight(primary);
  final (matches, unmatched) = _matchSecondary(primary, secondary, tolerance);
  final placed = <_Placed>[];
  for (final (index, line) in primary.indexed) {
    final matched = [for (final i in matches[index]!) secondary[i]];
    if (matched.isEmpty) {
      placed.add(_Placed(line, _centerY(line)));
    } else if (matched.length == 1) {
      placed.addAll(_placeSingle(line, matched.single));
    } else {
      placed.addAll(_placeSeveral(line, matched));
    }
  }
  placed.addAll([
    for (final i in unmatched) _Placed(secondary[i], _centerY(secondary[i])),
  ]);
  final ordered = [for (final (i, entry) in placed.indexed) (i, entry)]
    ..sort((a, b) {
      final byCenter = a.$2.centerY.compareTo(b.$2.centerY);
      return byCenter != 0 ? byCenter : a.$1.compareTo(b.$1);
    });
  return FusedPass(
    lines: [for (final entry in ordered) entry.$2.line],
    alternatives: {
      for (final (index, entry) in ordered.indexed)
        index: ?entry.$2.alternativeCents,
    },
  );
}
