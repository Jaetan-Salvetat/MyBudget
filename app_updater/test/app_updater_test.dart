import 'package:flutter_test/flutter_test.dart';

import 'package:app_updater/app_updater.dart';

void main() {
  group('ReleaseInfo', () {
    test('defaultApkAsset returns first .apk asset', () {
      final release = ReleaseInfo(
        version: '1.0.0',
        tagName: 'v1.0.0',
        title: 'Test',
        notes: '',
        publishedAt: DateTime(2024),
        isPrerelease: false,
        assets: [
          const ReleaseAsset(
            name: 'checksums.txt',
            downloadUrl: 'https://example.com/checksums.txt',
            size: 100,
            contentType: 'text/plain',
          ),
          const ReleaseAsset(
            name: 'app-release.apk',
            downloadUrl: 'https://example.com/app-release.apk',
            size: 50000,
            contentType: 'application/vnd.android.package-archive',
          ),
        ],
      );

      expect(release.defaultApkAsset, isNotNull);
      expect(release.defaultApkAsset!.name, 'app-release.apk');
    });

    test('defaultApkAsset returns null when no .apk asset', () {
      final release = ReleaseInfo(
        version: '1.0.0',
        tagName: 'v1.0.0',
        title: 'Test',
        notes: '',
        publishedAt: DateTime(2024),
        isPrerelease: false,
        assets: [
          const ReleaseAsset(
            name: 'source.zip',
            downloadUrl: 'https://example.com/source.zip',
            size: 1000,
            contentType: 'application/zip',
          ),
        ],
      );

      expect(release.defaultApkAsset, isNull);
    });

    test('fromJson parses correctly', () {
      final json = {
        'tag_name': 'v2.0.0',
        'name': 'Release 2.0',
        'body': 'Big update',
        'published_at': '2024-06-01T12:00:00Z',
        'prerelease': true,
        'assets': [
          {
            'name': 'app.apk',
            'browser_download_url': 'https://example.com/app.apk',
            'size': 2048,
            'content_type': 'application/vnd.android.package-archive',
          },
        ],
      };

      final release = ReleaseInfo.fromJson(json);

      expect(release.version, '2.0.0');
      expect(release.tagName, 'v2.0.0');
      expect(release.title, 'Release 2.0');
      expect(release.notes, 'Big update');
      expect(release.isPrerelease, true);
      expect(release.assets, hasLength(1));
    });

    test('fromJson handles null name and body', () {
      final json = {
        'tag_name': 'v1.0.0',
        'name': null,
        'body': null,
        'published_at': '2024-01-01T00:00:00Z',
        'prerelease': false,
        'assets': <dynamic>[],
      };

      final release = ReleaseInfo.fromJson(json);

      expect(release.title, '');
      expect(release.notes, '');
    });
  });

  group('UpdateException hierarchy', () {
    test('NetworkException toString', () {
      const e = NetworkException('No internet');
      expect(e.toString(), 'NetworkException: No internet');
    });

    test('GitHubApiException toString', () {
      const e = GitHubApiException(statusCode: 403, message: 'Rate limited');
      expect(e.toString(), 'GitHubApiException(403): Rate limited');
    });

    test('DownloadException toString', () {
      const e = DownloadException(
        url: 'https://example.com/app.apk',
        attempts: 3,
      );
      expect(e.toString(), contains('attempts: 3'));
    });

    test('InstallException toString', () {
      const e = InstallException(filePath: '/tmp/app.apk');
      expect(e.toString(), contains('/tmp/app.apk'));
    });

    test('VersionParseException toString', () {
      const e = VersionParseException(version: 'abc');
      expect(e.toString(), contains('abc'));
    });

    test('all exceptions are UpdateException', () {
      expect(const NetworkException(), isA<UpdateException>());
      expect(
        const GitHubApiException(statusCode: 500),
        isA<UpdateException>(),
      );
      expect(
        const DownloadException(url: '', attempts: 0),
        isA<UpdateException>(),
      );
      expect(
        const InstallException(filePath: ''),
        isA<UpdateException>(),
      );
      expect(
        const VersionParseException(version: ''),
        isA<UpdateException>(),
      );
    });
  });

  group('UpdateConfig', () {
    test('has sensible defaults', () {
      const config = UpdateConfig(
        githubOwner: 'owner',
        githubRepo: 'repo',
      );

      expect(config.channel, UpdateChannel.stable);
      expect(config.maxRetries, 3);
      expect(config.retryDelay, const Duration(seconds: 2));
      expect(config.githubToken, isNull);
      expect(config.currentVersion, isNull);
      expect(config.versionComparator, isNull);
      expect(config.assetSelector, isNull);
      expect(config.httpClient, isNull);
    });
  });

}
