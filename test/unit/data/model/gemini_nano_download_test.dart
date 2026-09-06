import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/data/model/gemini_nano_download.dart';

void main() {
  group('GeminiNanoDownloadProgress.ratio', () {
    test('rapporte l\'avancement sur le total annoncé au démarrage', () {
      const progress = GeminiNanoDownloadProgress(
        downloadedBytes: 250,
        totalBytes: 1000,
      );

      expect(progress.ratio, 0.25);
    });

    test('reste inconnu tant que le total n\'est pas connu', () {
      const progress = GeminiNanoDownloadProgress(
        downloadedBytes: 250,
        totalBytes: 0,
      );

      expect(progress.ratio, isNull);
    });

    test('borne à 1 si le natif annonce plus que le total', () {
      const progress = GeminiNanoDownloadProgress(
        downloadedBytes: 1200,
        totalBytes: 1000,
      );

      expect(progress.ratio, 1);
    });
  });
}
