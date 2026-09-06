import 'dart:typed_data';

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
