library;

import 'dart:convert';
import 'dart:math' as math;

import 'structure.dart' show foldAccents;

const int hashBuckets = 64;

final RegExp _digitPattern = RegExp(r'\d');
final RegExp _whitespaceRun = RegExp(r'\s+');

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

int crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

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
