/// Les signaux qu'une ligne de ticket porte, sans modèle ni featuriseur.
///
/// Ils décrivent des faits typographiques indépendants du modèle qui les lit :
/// les featuriseurs de lignes et de mots s'en servent tous les deux.
///
/// Ils vivaient dans `line_features.dart`, à côté du featuriseur du
/// classifieur V2/V3. Ce classifieur est mort — le tagger de rôles fait mieux
/// ce qu'il faisait — mais les signaux, eux, lui survivent.
///
/// Miroir de `ml/scan/research/reference/line_signals.py`, restreint aux
/// signaux qu'un modèle embarqué consomme : les signaux arithmétiques
/// (`block_sum_matches`, `tax_shaped`, `discount_summary`) et flous
/// (`fuzzy_lexicon_similarity`) n'y servent qu'à construire la vérité de
/// rôle, côté Python, et n'ont donc pas de portage.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'structure.dart' show foldAccents;

const int hashBuckets = 64;

final RegExp _digitPattern = RegExp(r'\d');
final RegExp _whitespaceRun = RegExp(r'\s+');

/// Le texte replié sur ce que l'OCR ne peut pas confondre : accents retirés,
/// et les trois substitutions que tout moteur fait sur du thermique pâli.
String normalizedText(String text) => foldAccents(text.toUpperCase())
    .replaceAll('0', 'O')
    .replaceAll('1', 'I')
    .replaceAll('5', 'S');

final List<int> _crcTable = _buildCrcTable();

List<int> _buildCrcTable() {
  final table = List<int>.filled(256, 0);
  for (var i = 0; i < 256; i++) {
    var crc = i;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
    table[i] = crc;
  }
  return table;
}

/// CRC-32 (IEEE 802.3), identique à `zlib.crc32` côté Python.
int crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

/// Empreinte du texte en trigrammes hachés : les chiffres deviennent `#`, si
/// bien qu'un libellé et le même libellé à un autre prix tombent au même
/// endroit.
List<double> hashedTrigrams(String text, int buckets) {
  var folded = normalizedText(text.replaceAll(_digitPattern, '#'));
  folded = folded.replaceAll(_whitespaceRun, ' ').trim();
  final padded = ' $folded ';
  final vector = List<double>.filled(buckets, 0.0);
  for (var start = 0; start < math.max(padded.length - 2, 0); start++) {
    final trigram = padded.substring(start, start + 3);
    vector[crc32(utf8.encode(trigram)) % buckets] = 1.0;
  }
  return vector;
}
