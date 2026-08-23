import 'dart:convert';

import 'package:app_updater/app_updater.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_updater/src/services/github_service.dart';

Map<String, dynamic> _makeRelease({
  String tagName = 'v1.0.0',
  bool prerelease = false,
  String assetName = 'app.apk',
}) {
  return {
    'tag_name': tagName,
    'name': 'Release $tagName',
    'body': 'Release notes',
    'published_at': '2024-01-01T00:00:00Z',
    'prerelease': prerelease,
    'assets': [
      {
        'name': assetName,
        'browser_download_url': 'https://example.com/$assetName',
        'size': 1024,
        'content_type': 'application/vnd.android.package-archive',
      },
    ],
  };
}

void main() {
  group('GitHubService', () {
    GitHubService createService(http.Client client, {String? token}) {
      return GitHubService(
        owner: 'test-owner',
        repo: 'test-repo',
        token: token,
        client: client,
      );
    }

    test('parses releases correctly', () async {
      final client = http_testing.MockClient((_) async {
        return http.Response(
          jsonEncode([_makeRelease(tagName: 'v2.1.0')]),
          200,
        );
      });

      final service = createService(client);
      final releases = await service.getReleases();

      expect(releases, hasLength(1));
      expect(releases.first.version, '2.1.0');
      expect(releases.first.tagName, 'v2.1.0');
      expect(releases.first.title, 'Release v2.1.0');
      expect(releases.first.isPrerelease, false);
      expect(releases.first.assets, hasLength(1));
      expect(releases.first.assets.first.name, 'app.apk');
    });

    test('strips v prefix from version', () async {
      final client = http_testing.MockClient((_) async {
        return http.Response(
          jsonEncode([_makeRelease(tagName: 'v1.2.3')]),
          200,
        );
      });

      final service = createService(client);
      final releases = await service.getReleases();

      expect(releases.first.version, '1.2.3');
    });

    test('handles tag without v prefix', () async {
      final client = http_testing.MockClient((_) async {
        return http.Response(
          jsonEncode([_makeRelease(tagName: '1.2.3')]),
          200,
        );
      });

      final service = createService(client);
      final releases = await service.getReleases();

      expect(releases.first.version, '1.2.3');
      expect(releases.first.tagName, '1.2.3');
    });

    test('skips malformed releases', () async {
      final client = http_testing.MockClient((_) async {
        return http.Response(
          jsonEncode([
            _makeRelease(tagName: 'v1.0.0'),
            {'bad': 'data'},
          ]),
          200,
        );
      });

      final service = createService(client);
      final releases = await service.getReleases();

      expect(releases, hasLength(1));
    });

    test('throws GitHubApiException on non-200 response', () async {
      final client = http_testing.MockClient((_) async {
        return http.Response('Not Found', 404);
      });

      final service = createService(client);

      expect(
        () => service.getReleases(),
        throwsA(isA<GitHubApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          404,
        )),
      );
    });

    test('throws GitHubApiException on rate limit', () async {
      final client = http_testing.MockClient((_) async {
        return http.Response('Rate limited', 403);
      });

      final service = createService(client);

      expect(
        () => service.getReleases(),
        throwsA(isA<GitHubApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          403,
        )),
      );
    });

    test('throws NetworkException on client exception', () async {
      final client = http_testing.MockClient((_) async {
        throw http.ClientException('Connection failed');
      });

      final service = createService(client);

      expect(
        () => service.getReleases(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('includes authorization header when token provided', () async {
      String? authHeader;
      final client = http_testing.MockClient((request) async {
        authHeader = request.headers['Authorization'];
        return http.Response(jsonEncode([]), 200);
      });

      final service = createService(client, token: 'my-token');
      await service.getReleases();

      expect(authHeader, 'token my-token');
    });

    test('does not include authorization header without token', () async {
      String? authHeader;
      final client = http_testing.MockClient((request) async {
        authHeader = request.headers['Authorization'];
        return http.Response(jsonEncode([]), 200);
      });

      final service = createService(client);
      await service.getReleases();

      expect(authHeader, isNull);
    });

    group('filterByChannel', () {
      final service = GitHubService(
        owner: 'test',
        repo: 'test',
      );

      final stable = ReleaseInfo(
        version: '1.0.0',
        tagName: 'v1.0.0',
        title: 'Stable',
        notes: '',
        publishedAt: DateTime(2024),
        isPrerelease: false,
        assets: [],
      );

      final beta = ReleaseInfo(
        version: '1.1.0-beta.1',
        tagName: 'v1.1.0-beta.1',
        title: 'Beta',
        notes: '',
        publishedAt: DateTime(2024),
        isPrerelease: true,
        assets: [],
      );

      test('filters stable releases', () {
        final result =
            service.filterByChannel([stable, beta], UpdateChannel.stable);
        expect(result, [stable]);
      });

      test('filters beta releases', () {
        final result =
            service.filterByChannel([stable, beta], UpdateChannel.beta);
        expect(result, [beta]);
      });
    });
  });
}
