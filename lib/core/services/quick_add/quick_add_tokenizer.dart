import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:mybudget/core/services/models/model_asset.dart';
import 'package:mybudget/core/services/quick_add/quick_add_tokenizer_format.dart';

typedef TokenizedInput = ({List<int> inputIds, List<int> attentionMask});

typedef _Symbol = ({String text, int id});

class QuickAddTokenizer {
  /// Le tokenizer porte la version des modeles : il est publie avec eux et
  /// doit correspondre au graphe ONNX qui consomme ses identifiants.
  static final RegExp assetPattern = RegExp(
    r'^assets/models/tokenizer_v\d+\.bin$',
  );

  /// Le graphe ONNX accepte une longueur libre : on pade au plus petit palier
  /// qui contient la saisie plutot qu'au maximum, le modele ne calculant alors
  /// plus les positions de bourrage. Quelques paliers seulement, pour qu'ORT
  /// reutilise ses buffers au lieu d'en reallouer a chaque forme inedite.
  static const List<int> lengthBuckets = [8, 16, 32, 64];
  static const int _padId = 0;
  static const int _bosId = 2;
  static const int _eosId = 1;
  static const int _unkId = 3;
  static const String _metaspace = '▁';

  static const int _absent = -1;
  static const int _wordBytes = 4;

  late final ByteData _data;
  late final int _vocabCount;
  late final int _mergeCount;
  late final int _vocabIdsOffset;
  late final int _vocabBlobOffset;
  late final int _mergesOffset;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Aucune table n'est construite ici : les sections sont deja triees, on ne
  /// retient que leurs positions et les recherches lisent les octets en place.
  Future<void> load() async {
    if (_loaded) return;

    final assetPath = await modelAssetFromManifest(
      assetPattern,
      'tokenizer quick-add',
    );
    final asset = await rootBundle.load(assetPath);
    final bytes = asset.buffer.asUint8List(
      asset.offsetInBytes,
      asset.lengthInBytes,
    );
    if (!QuickAddTokenizerFormat.hasMagic(bytes)) {
      throw FormatException('Tokenizer illisible : en-tete inattendu dans $assetPath');
    }

    _data = ByteData.view(
      asset.buffer,
      asset.offsetInBytes,
      asset.lengthInBytes,
    );

    final version = _uint32(QuickAddTokenizerFormat.versionOffset);
    if (version != QuickAddTokenizerFormat.version) {
      throw FormatException(
        'Tokenizer en version $version, '
        '${QuickAddTokenizerFormat.version} attendue dans $assetPath',
      );
    }

    _vocabCount = _uint32(QuickAddTokenizerFormat.vocabCountOffset);
    _mergeCount = _uint32(QuickAddTokenizerFormat.mergeCountOffset);
    _vocabIdsOffset = QuickAddTokenizerFormat.vocabIdsOffset(_vocabCount);
    _vocabBlobOffset = QuickAddTokenizerFormat.vocabBlobOffset(_vocabCount);
    _mergesOffset = QuickAddTokenizerFormat.mergesOffset(
      _vocabCount,
      _tokenBound(_vocabCount),
    );

    _loaded = true;
  }

  TokenizedInput encode(String text) {
    assert(_loaded, 'Tokenizer not loaded. Call load() first.');

    final normalized = '$_metaspace${text.replaceAll(' ', _metaspace)}';
    final symbols = _bpeEncode(normalized);

    final ids = <int>[_bosId];
    for (final symbol in symbols) {
      if (symbol.id != _absent) {
        ids.add(symbol.id);
        continue;
      }
      for (final char in symbol.text.runes) {
        ids.add(_tokenId(String.fromCharCode(char)) ?? _unkId);
      }
    }
    ids.add(_eosId);

    final maxLength = lengthBuckets.last;
    if (ids.length > maxLength) {
      final truncated = ids.sublist(0, maxLength - 1)..add(_eosId);
      return (inputIds: truncated, attentionMask: List.filled(maxLength, 1));
    }

    final padLength = _bucketFor(ids.length) - ids.length;
    return (
      inputIds: ids + List.filled(padLength, _padId),
      attentionMask: List.filled(ids.length, 1) + List.filled(padLength, 0),
    );
  }

  int _bucketFor(int length) {
    return lengthBuckets.firstWhere(
      (bucket) => length <= bucket,
      orElse: () => lengthBuckets.last,
    );
  }

  /// Chaque symbole porte son identifiant : les fusions se cherchent par paire
  /// d'identifiants, et un symbole absent du vocabulaire — seuls les caracteres
  /// inconnus le sont — ne participe a aucune fusion.
  List<_Symbol> _bpeEncode(String text) {
    var symbols = text
        .split('')
        .map<_Symbol>((char) => (text: char, id: _tokenId(char) ?? _absent))
        .toList();

    while (symbols.length > 1) {
      int bestRank = _absent;
      int bestIdx = _absent;

      for (int i = 0; i < symbols.length - 1; i++) {
        if (symbols[i].id == _absent || symbols[i + 1].id == _absent) continue;
        final rank = _mergeRank(symbols[i].id, symbols[i + 1].id);
        if (rank != null && (bestRank == _absent || rank < bestRank)) {
          bestRank = rank;
          bestIdx = i;
        }
      }

      if (bestIdx == _absent) break;

      final merged = symbols[bestIdx].text + symbols[bestIdx + 1].text;
      symbols = [
        ...symbols.sublist(0, bestIdx),
        (text: merged, id: _tokenId(merged) ?? _absent),
        ...symbols.sublist(bestIdx + 2),
      ];
    }

    return symbols;
  }

  int? _tokenId(String token) {
    final needle = utf8.encode(token);
    int low = 0;
    int high = _vocabCount - 1;

    while (low <= high) {
      final middle = (low + high) >> 1;
      final comparison = _compareToken(needle, middle);
      if (comparison == 0) {
        return _uint32(_vocabIdsOffset + middle * _wordBytes);
      }
      if (comparison < 0) {
        high = middle - 1;
      } else {
        low = middle + 1;
      }
    }
    return null;
  }

  int _compareToken(List<int> needle, int index) {
    final start = _vocabBlobOffset + _tokenBound(index);
    final end = _vocabBlobOffset + _tokenBound(index + 1);
    final length = end - start;
    final shortest = needle.length < length ? needle.length : length;

    for (int i = 0; i < shortest; i++) {
      final difference = needle[i] - _data.getUint8(start + i);
      if (difference != 0) return difference;
    }
    return needle.length - length;
  }

  int? _mergeRank(int left, int right) {
    int low = 0;
    int high = _mergeCount - 1;

    while (low <= high) {
      final middle = (low + high) >> 1;
      final record =
          _mergesOffset + middle * QuickAddTokenizerFormat.mergeRecordBytes;
      final candidateLeft = _uint32(record);
      final candidateRight = _uint32(record + _wordBytes);

      if (candidateLeft == left && candidateRight == right) {
        return _uint32(record + 2 * _wordBytes);
      }
      if (candidateLeft < left ||
          (candidateLeft == left && candidateRight < right)) {
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    return null;
  }

  int _tokenBound(int index) =>
      _uint32(QuickAddTokenizerFormat.vocabBoundsOffset() + index * _wordBytes);

  int _uint32(int offset) => _data.getUint32(offset, Endian.little);
}
