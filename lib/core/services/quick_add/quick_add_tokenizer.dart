import 'dart:convert';

import 'package:flutter/services.dart';

typedef TokenizedInput = ({List<int> inputIds, List<int> attentionMask});

class QuickAddTokenizer {
  static const String assetPath = 'assets/models/tokenizer.json';
  static const int _maxLength = 64;
  static const int _padId = 0;
  static const int _bosId = 2;
  static const int _eosId = 1;
  static const int _unkId = 3;
  static const String _metaspace = '▁';

  late final Map<String, int> _vocab;
  late final Map<String, int> _mergeRanks;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;

    final jsonStr = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> tokenizer = json.decode(jsonStr);
    final Map<String, dynamic> model = tokenizer['model'];

    final Map<String, dynamic> rawVocab = model['vocab'];
    _vocab = rawVocab.map((key, value) => MapEntry(key, value as int));

    final List<dynamic> rawMerges = model['merges'];
    _mergeRanks = {};
    for (int i = 0; i < rawMerges.length; i++) {
      final List<dynamic> pair = rawMerges[i];
      _mergeRanks['${pair[0]} ${pair[1]}'] = i;
    }

    _loaded = true;
  }

  TokenizedInput encode(String text) {
    assert(_loaded, 'Tokenizer not loaded. Call load() first.');

    final normalized = '$_metaspace${text.replaceAll(' ', _metaspace)}';
    final tokens = _bpeEncode(normalized);

    final ids = <int>[_bosId];
    for (final token in tokens) {
      final id = _vocab[token];
      if (id != null) {
        ids.add(id);
      } else {
        for (final char in token.runes) {
          final charStr = String.fromCharCode(char);
          ids.add(_vocab[charStr] ?? _unkId);
        }
      }
    }
    ids.add(_eosId);

    if (ids.length > _maxLength) {
      final truncated = ids.sublist(0, _maxLength - 1)..add(_eosId);
      return (
        inputIds: truncated,
        attentionMask: List.filled(_maxLength, 1),
      );
    }

    final padLength = _maxLength - ids.length;
    return (
      inputIds: ids + List.filled(padLength, _padId),
      attentionMask: List.filled(ids.length, 1) + List.filled(padLength, 0),
    );
  }

  List<String> _bpeEncode(String text) {
    List<String> symbols = text.split('').toList();

    while (symbols.length > 1) {
      int bestRank = -1;
      int bestIdx = -1;

      for (int i = 0; i < symbols.length - 1; i++) {
        final pair = '${symbols[i]} ${symbols[i + 1]}';
        final rank = _mergeRanks[pair];
        if (rank != null && (bestRank == -1 || rank < bestRank)) {
          bestRank = rank;
          bestIdx = i;
        }
      }

      if (bestIdx == -1) break;

      final merged = symbols[bestIdx] + symbols[bestIdx + 1];
      symbols = [
        ...symbols.sublist(0, bestIdx),
        merged,
        ...symbols.sublist(bestIdx + 2),
      ];
    }

    return symbols;
  }
}
