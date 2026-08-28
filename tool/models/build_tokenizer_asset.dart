import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mybudget/core/services/quick_add/quick_add_tokenizer_format.dart';

/// Convertit le `tokenizer.json` HuggingFace en asset binaire embarque.
///
/// A relancer apres chaque reentrainement :
/// `dart run tool/build_tokenizer_asset.dart <tokenizer.json> <tokenizer.bin>`
Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln(
      'usage: dart run tool/build_tokenizer_asset.dart '
      '<tokenizer.json> <tokenizer.bin>',
    );
    exitCode = 64;
    return;
  }

  final source = File(args.first);
  if (!source.existsSync()) {
    stderr.writeln('Fichier introuvable : ${source.path}');
    exitCode = 66;
    return;
  }

  final Map<String, dynamic> tokenizer = json.decode(
    await source.readAsString(),
  );
  final Map<String, dynamic> model = tokenizer['model'];

  final vocab = (model['vocab'] as Map<String, dynamic>).map(
    (token, id) => MapEntry(token, id as int),
  );
  final merges = (model['merges'] as List<dynamic>)
      .map((pair) => ((pair as List<dynamic>)[0] as String, pair[1] as String))
      .toList();

  final encoded = encodeTokenizer(vocab: vocab, merges: merges);
  await File(args.last).writeAsBytes(encoded.bytes, flush: true);

  stdout.writeln(
    '${args.last} : ${(encoded.bytes.length / 1024 / 1024).toStringAsFixed(1)} '
    'Mo, ${vocab.length} tokens, ${merges.length} fusions'
    '${encoded.skippedMerges == 0 ? '' : ' (${encoded.skippedMerges} ignorées)'}',
  );
}

typedef EncodedTokenizer = ({Uint8List bytes, int skippedMerges});

/// Une fusion dont une moitie n'est pas dans le vocabulaire ne peut jamais
/// s'appliquer — l'encodeur ne manipule que des symboles connus — et ne peut
/// donc pas etre designee par identifiant : on la laisse de cote plutot que
/// d'inventer un identifiant qui fausserait les recherches.
EncodedTokenizer encodeTokenizer({
  required Map<String, int> vocab,
  required List<(String, String)> merges,
}) {
  // L'identifiant voyage avec les octets du token : `utf8.decode` ne rend pas
  // toujours la clef d'origine (surrogates isoles du vocabulaire), un
  // aller-retour par le texte perdrait ces entrees.
  final entries = vocab.entries
      .map((entry) => (bytes: utf8.encode(entry.key), id: entry.value))
      .toList()
    ..sort((a, b) => _compareBytes(a.bytes, b.bytes));

  final tokens = entries.map((entry) => entry.bytes).toList();
  final bounds = Uint32List(tokens.length + 1);
  final ids = Uint32List(tokens.length);
  var blobBytes = 0;
  for (int i = 0; i < tokens.length; i++) {
    bounds[i] = blobBytes;
    ids[i] = entries[i].id;
    blobBytes += tokens[i].length;
  }
  bounds[tokens.length] = blobBytes;

  final records = <List<int>>[];
  for (int rank = 0; rank < merges.length; rank++) {
    final left = vocab[merges[rank].$1];
    final right = vocab[merges[rank].$2];
    if (left == null || right == null) continue;
    records.add([left, right, rank]);
  }
  records.sort((a, b) => a[0] == b[0] ? a[1].compareTo(b[1]) : a[0] - b[0]);

  final mergesOffset = QuickAddTokenizerFormat.mergesOffset(
    tokens.length,
    blobBytes,
  );
  final total =
      mergesOffset +
      records.length * QuickAddTokenizerFormat.mergeRecordBytes;

  final bytes = Uint8List(total);
  final header = ByteData.view(bytes.buffer);
  bytes.setRange(0, QuickAddTokenizerFormat.magic.length, QuickAddTokenizerFormat.magic);
  header.setUint32(
    QuickAddTokenizerFormat.versionOffset,
    QuickAddTokenizerFormat.version,
    Endian.little,
  );
  header.setUint32(
    QuickAddTokenizerFormat.vocabCountOffset,
    tokens.length,
    Endian.little,
  );
  header.setUint32(
    QuickAddTokenizerFormat.mergeCountOffset,
    records.length,
    Endian.little,
  );

  bytes.setRange(
    QuickAddTokenizerFormat.vocabBoundsOffset(),
    QuickAddTokenizerFormat.vocabIdsOffset(tokens.length),
    bounds.buffer.asUint8List(),
  );
  bytes.setRange(
    QuickAddTokenizerFormat.vocabIdsOffset(tokens.length),
    QuickAddTokenizerFormat.vocabBlobOffset(tokens.length),
    ids.buffer.asUint8List(),
  );

  var cursor = QuickAddTokenizerFormat.vocabBlobOffset(tokens.length);
  for (final token in tokens) {
    bytes.setRange(cursor, cursor + token.length, token);
    cursor += token.length;
  }

  final flatRecords = Uint32List(records.length * 3);
  for (int i = 0; i < records.length; i++) {
    flatRecords[i * 3] = records[i][0];
    flatRecords[i * 3 + 1] = records[i][1];
    flatRecords[i * 3 + 2] = records[i][2];
  }
  bytes.setRange(mergesOffset, total, flatRecords.buffer.asUint8List());

  return (bytes: bytes, skippedMerges: merges.length - records.length);
}

int _compareBytes(List<int> a, List<int> b) {
  final shortest = a.length < b.length ? a.length : b.length;
  for (int i = 0; i < shortest; i++) {
    if (a[i] != b[i]) return a[i] - b[i];
  }
  return a.length - b.length;
}
