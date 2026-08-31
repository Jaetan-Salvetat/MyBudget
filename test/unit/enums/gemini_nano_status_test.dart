import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/gemini_nano_status.dart';

void main() {
  group('GeminiNanoStatus', () {
    test('résout chaque identifiant du canal natif', () {
      for (final status in GeminiNanoStatus.values) {
        expect(GeminiNanoStatus.fromId(status.id), status);
      }
    });

    test('retombe sur unavailable pour un identifiant inconnu ou nul', () {
      expect(GeminiNanoStatus.fromId('downloaded'), GeminiNanoStatus.unavailable);
      expect(GeminiNanoStatus.fromId(null), GeminiNanoStatus.unavailable);
    });

    test('seul available est utilisable', () {
      expect(GeminiNanoStatus.available.isReady, isTrue);
      expect(GeminiNanoStatus.downloadable.isReady, isFalse);
      expect(GeminiNanoStatus.downloading.isReady, isFalse);
      expect(GeminiNanoStatus.unavailable.isReady, isFalse);
    });

    test('seul downloadable se télécharge', () {
      expect(GeminiNanoStatus.downloadable.isDownloadable, isTrue);
      expect(GeminiNanoStatus.downloading.isDownloadable, isFalse);
      expect(GeminiNanoStatus.unavailable.isDownloadable, isFalse);
    });

    test('le mode est sélectionnable sauf si l\'appareil ne suit pas', () {
      expect(GeminiNanoStatus.available.isSelectable, isTrue);
      expect(GeminiNanoStatus.downloadable.isSelectable, isTrue);
      expect(GeminiNanoStatus.downloading.isSelectable, isTrue);
      expect(GeminiNanoStatus.unavailable.isSelectable, isFalse);
    });
  });
}
