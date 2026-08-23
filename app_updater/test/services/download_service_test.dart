import 'package:flutter_test/flutter_test.dart';

import 'package:app_updater/src/services/download_service.dart';

void main() {
  group('DownloadService.fileNameFromUrl', () {
    test('extracts filename from URL', () {
      expect(
        DownloadService.fileNameFromUrl(
          'https://github.com/user/repo/releases/download/v1.0.0/app-release.apk',
        ),
        'app-release.apk',
      );
    });

    test('returns default for non-apk URL', () {
      expect(
        DownloadService.fileNameFromUrl('https://example.com/file.zip'),
        'update.apk',
      );
    });

    test('returns default for empty URL', () {
      expect(DownloadService.fileNameFromUrl(''), 'update.apk');
    });

    test('returns default for invalid URL', () {
      expect(DownloadService.fileNameFromUrl('not a url'), 'update.apk');
    });
  });
}
