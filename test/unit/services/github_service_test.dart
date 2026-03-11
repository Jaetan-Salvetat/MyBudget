import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/services/github_service.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late GitHubService service;
  late MockHttpClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockHttpClient();
    service = GitHubService(client: mockHttpClient);
    registerFallbackValue(Uri.parse('http://test.com'));
  });

  group('GitHubService Tests', () {
    const successJson = '''
    [
      {
        "tag_name": "v1.1.0",
        "name": "Release 1.1.0",
        "body": "Notes",
        "published_at": "2023-01-01T00:00:00Z",
        "prerelease": false,
        "assets": [
          {
            "name": "app.apk",
            "browser_download_url": "http://url.apk",
            "size": 1024
          }
        ]
      },
      {
        "tag_name": "v1.2.0-beta.1",
        "name": "Beta 1.2.0-beta.1",
        "body": "Beta Notes",
        "published_at": "2023-02-01T00:00:00Z",
        "prerelease": true,
        "assets": [
           {
            "name": "app-beta.apk",
            "browser_download_url": "http://beta.apk",
            "size": 2048
          }
        ]
      }
    ]
    ''';

    const noAssetsJson = '''
    [
      {
        "tag_name": "v1.0.0",
        "name": "Release 1.0.0",
        "body": "Notes",
        "published_at": "2023-01-01T00:00:00Z",
        "prerelease": false,
        "assets": []
      }
    ]
    ''';

    test('getReleases should return list of ReleaseInfo on 200 OK', () async {
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(successJson, 200));

      final releases = await service.getReleases();

      expect(releases.length, 2);
      expect(releases[0].version, '1.1.0');
      expect(releases[0].downloadUrl, 'http://url.apk');
      expect(releases[1].isPrerelease, true);
    });

    test('getReleases should ignore releases without APK assets', () async {
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(noAssetsJson, 200));

      final releases = await service.getReleases();

      expect(releases, isEmpty);
    });

    test('getReleases should return empty list on API error', () async {
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Error', 404));

      final releases = await service.getReleases();
      expect(releases, isEmpty);
    });

    test('getReleases should return empty list on Network exception', () async {
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('Network Error'));

      final releases = await service.getReleases();
      expect(releases, isEmpty);
    });

    test('getReleases should preserve -beta.N suffix in tag version', () async {
      const betaDotNJson = '''
      [
        {
          "tag_name": "v1.2.0-beta.3",
          "name": "Beta 1.2.0-beta.3",
          "body": "Beta Notes",
          "published_at": "2023-02-01T00:00:00Z",
          "prerelease": true,
          "assets": [
            {
              "name": "app-beta.apk",
              "browser_download_url": "http://beta.apk",
              "size": 2048
            }
          ]
        }
      ]
      ''';

      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(betaDotNJson, 200));

      final releases = await service.getReleases();

      expect(releases.length, 1);
      expect(releases[0].version, '1.2.0-beta.3');
      expect(releases[0].isPrerelease, true);
    });
  });
}
