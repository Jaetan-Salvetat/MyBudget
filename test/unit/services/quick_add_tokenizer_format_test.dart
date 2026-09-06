import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/quick_add/quick_add_tokenizer_format.dart';

import '../../../tool/models/build_tokenizer_asset.dart';

void main() {
  int uint32(Uint8List bytes, int offset) =>
      ByteData.view(bytes.buffer).getUint32(offset, Endian.little);

  group('encodeTokenizer', () {
    test('ecrit un en-tete reconnaissable et versionne', () {
      final encoded = encodeTokenizer(
        vocab: {'a': 0, 'b': 1},
        merges: [('a', 'b')],
      );

      expect(QuickAddTokenizerFormat.hasMagic(encoded.bytes), isTrue);
      expect(
        uint32(encoded.bytes, QuickAddTokenizerFormat.versionOffset),
        QuickAddTokenizerFormat.version,
      );
      expect(
        uint32(encoded.bytes, QuickAddTokenizerFormat.vocabCountOffset),
        2,
      );
      expect(
        uint32(encoded.bytes, QuickAddTokenizerFormat.mergeCountOffset),
        1,
      );
    });

    test('trie le vocabulaire par octets et non par identifiant', () {
      final encoded = encodeTokenizer(vocab: {'z': 0, 'a': 1}, merges: []);

      final blob = QuickAddTokenizerFormat.vocabBlobOffset(2);
      expect(encoded.bytes[blob], 'a'.codeUnitAt(0));
      expect(encoded.bytes[blob + 1], 'z'.codeUnitAt(0));
      expect(
        uint32(encoded.bytes, QuickAddTokenizerFormat.vocabIdsOffset(2)),
        1,
      );
    });

    test('conserve le rang d origine malgre le tri des fusions', () {
      final encoded = encodeTokenizer(
        vocab: {'a': 0, 'b': 1, 'c': 2},
        merges: [('b', 'c'), ('a', 'b')],
      );

      final merges = QuickAddTokenizerFormat.mergesOffset(3, 3);
      expect(uint32(encoded.bytes, merges), 0);
      expect(uint32(encoded.bytes, merges + 4), 1);
      expect(uint32(encoded.bytes, merges + 8), 1);
    });

    test('ignore une fusion dont une moitie manque au vocabulaire', () {
      final encoded = encodeTokenizer(
        vocab: {'a': 0, 'b': 1},
        merges: [('a', 'b'), ('a', 'absent')],
      );

      expect(encoded.skippedMerges, 1);
      expect(
        uint32(encoded.bytes, QuickAddTokenizerFormat.mergeCountOffset),
        1,
      );
    });

    test('aligne les fusions apres un blob de longueur quelconque', () {
      final encoded = encodeTokenizer(
        vocab: {'abc': 0, 'de': 1},
        merges: [('abc', 'de')],
      );

      final merges = QuickAddTokenizerFormat.mergesOffset(2, 5);
      expect(merges % 4, 0);
      expect(encoded.bytes.length, merges + 12);
    });

    test('accepte un vocabulaire non ASCII', () {
      final encoded = encodeTokenizer(vocab: {'▁': 0, 'é': 1}, merges: []);

      expect(
        uint32(encoded.bytes, QuickAddTokenizerFormat.vocabCountOffset),
        2,
      );
      expect(QuickAddTokenizerFormat.hasMagic(encoded.bytes), isTrue);
    });
  });
}
