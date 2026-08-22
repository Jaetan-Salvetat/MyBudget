import 'package:app_updater/app_updater.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/settings/update_provider.dart';

class MockAppUpdater extends Mock implements AppUpdater {}

void main() {
  late MockAppUpdater mockUpdater;

  setUpAll(() {
    registerFallbackValue(
      ReleaseInfo(
        version: '0.0.0',
        tagName: 'v0.0.0',
        title: '',
        notes: '',
        publishedAt: DateTime(2020),
        isPrerelease: false,
        assets: const [],
      ),
    );
  });

  setUp(() {
    mockUpdater = MockAppUpdater();
    when(() => mockUpdater.currentVersion).thenReturn('1.0.0');
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [appUpdaterProvider.overrideWithValue(mockUpdater)],
    );
  }

  final testRelease = ReleaseInfo(
    version: '1.1.0',
    tagName: 'v1.1.0',
    title: 'Release 1.1.0',
    notes: 'Bug fixes',
    publishedAt: DateTime(2026, 3, 1),
    isPrerelease: false,
    assets: [
      const ReleaseAsset(
        name: 'app-release.apk',
        downloadUrl: 'https://example.com/app-release.apk',
        size: 50000000,
        contentType: 'application/vnd.android.package-archive',
      ),
    ],
  );

  group('UpdateNotifier - checkForUpdates', () {
    test('Should detect update when newer release exists', () async {
      when(
        () => mockUpdater.checkForUpdates(),
      ).thenAnswer((_) async => testRelease);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(updateProvider.notifier).checkForUpdates();

      final state = container.read(updateProvider);
      expect(state.availableUpdate, isNotNull);
      expect(state.availableUpdate?.version, '1.1.0');
      expect(state.isChecking, false);
      expect(state.error, isNull);
    });

    test('Should set null when no update available', () async {
      when(() => mockUpdater.checkForUpdates()).thenAnswer((_) async => null);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(updateProvider.notifier).checkForUpdates();

      final state = container.read(updateProvider);
      expect(state.availableUpdate, isNull);
      expect(state.isChecking, false);
      expect(state.error, isNull);
    });

    test('Should handle network error', () async {
      when(
        () => mockUpdater.checkForUpdates(),
      ).thenThrow(const NetworkException());

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(updateProvider.notifier).checkForUpdates();

      final state = container.read(updateProvider);
      expect(state.availableUpdate, isNull);
      expect(state.error, contains('réseau'));
      expect(state.isChecking, false);
    });

    test('Should handle GitHub API error', () async {
      when(
        () => mockUpdater.checkForUpdates(),
      ).thenThrow(const GitHubApiException(statusCode: 403));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(updateProvider.notifier).checkForUpdates();

      final state = container.read(updateProvider);
      expect(state.error, contains('403'));
      expect(state.isChecking, false);
    });

    test('Should handle generic error', () async {
      when(() => mockUpdater.checkForUpdates()).thenThrow(Exception('Unknown'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(updateProvider.notifier).checkForUpdates();

      final state = container.read(updateProvider);
      expect(state.error, isNotNull);
      expect(state.isChecking, false);
    });

    test('Should not check if already checking', () async {
      when(() => mockUpdater.checkForUpdates()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return testRelease;
      });

      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(updateProvider.notifier);
      final future1 = notifier.checkForUpdates();
      final future2 = notifier.checkForUpdates();

      await Future.wait([future1, future2]);

      verify(() => mockUpdater.checkForUpdates()).called(1);
    });

    test('Should set currentVersion from AppUpdater', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(updateProvider);
      expect(state.currentVersion, '1.0.0');
    });
  });

  group('UpdateNotifier - downloadUpdate', () {
    test('Should not download if no update available', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(updateProvider.notifier).downloadUpdate();

      final state = container.read(updateProvider);
      expect(state.isDownloading, false);
      verifyNever(() => mockUpdater.downloadUpdate(any()));
    });

    test('Should handle download error', () async {
      when(
        () => mockUpdater.checkForUpdates(),
      ).thenAnswer((_) async => testRelease);
      when(() => mockUpdater.downloadUpdate(any())).thenAnswer(
        (_) => Stream.error(
          const DownloadException(
            url: 'https://example.com/app.apk',
            attempts: 3,
          ),
        ),
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(updateProvider.notifier).checkForUpdates();
      await container.read(updateProvider.notifier).downloadUpdate();

      final state = container.read(updateProvider);
      expect(state.isDownloading, false);
      expect(state.error, contains('téléchargement'));
    });
  });
}
