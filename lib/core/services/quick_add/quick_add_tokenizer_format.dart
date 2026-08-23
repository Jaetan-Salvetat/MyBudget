import 'dart:typed_data';

/// Disposition du tokenizer embarque.
///
/// Le format HuggingFace coute plus a lire qu'a utiliser : 33 Mo de JSON a
/// decoder, puis deux tables de hachage de 256 000 et 580 000 entrees a bâtir
/// sur l'isolate qui dessine. Ici tout est trie a la generation, donc rien
/// n'est construit au chargement : les recherches se font directement dans les
/// octets, et charger revient a lire un fichier.
///
/// ```
/// 0   'MBTK'
/// 4   u32 version
/// 8   u32 vocabCount
/// 12  u32 mergeCount
/// 16  u32 * (vocabCount + 1)   bornes des tokens dans vocabBlob
///     u32 * vocabCount         identifiant de chaque token
///     bytes                    vocabBlob, tokens UTF-8 tries par octets
///     u32 * 3 * mergeCount     (gauche, droite, rang), tries par (gauche, droite)
/// ```
///
/// Les paires de fusion designent leurs deux moities par identifiant plutot
/// que par texte : un BPE entraine ne fusionne que des tokens du vocabulaire,
/// donc l'identifiant existe toujours, et comparer deux entiers evite de
/// reconstruire une clef texte a chaque comparaison.
class QuickAddTokenizerFormat {
  static const List<int> magic = [0x4D, 0x42, 0x54, 0x4B];
  static const int version = 1;

  static const int headerBytes = 16;
  static const int _wordBytes = 4;
  static const int mergeRecordBytes = 3 * _wordBytes;

  static const int versionOffset = 4;
  static const int vocabCountOffset = 8;
  static const int mergeCountOffset = 12;

  static int vocabBoundsOffset() => headerBytes;

  static int vocabIdsOffset(int vocabCount) =>
      vocabBoundsOffset() + (vocabCount + 1) * _wordBytes;

  static int vocabBlobOffset(int vocabCount) =>
      vocabIdsOffset(vocabCount) + vocabCount * _wordBytes;

  static int mergesOffset(int vocabCount, int vocabBlobBytes) =>
      vocabBlobOffset(vocabCount) + _padded(vocabBlobBytes);

  /// Les sections d'entiers sont lues via [Uint32List.view], qui exige un
  /// decalage multiple de quatre : le blob de texte qui les precede est donc
  /// complete jusqu'a la prochaine frontiere.
  static int _padded(int bytes) =>
      bytes + (bytes % _wordBytes == 0 ? 0 : _wordBytes - bytes % _wordBytes);

  static bool hasMagic(Uint8List bytes) {
    if (bytes.length < headerBytes) return false;
    for (int i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) return false;
    }
    return true;
  }
}
