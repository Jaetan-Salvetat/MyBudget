import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/services/download_service.dart';
import 'package:mybudget/core/services/github_service.dart';
import 'package:mybudget/core/services/install_service.dart';
import 'package:mybudget/models/release_info_model.dart';
import 'package:mybudget/ui/settings/update_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGitHubService extends Mock implements GitHubService {}

class MockDownloadService extends Mock implements DownloadService {}

class MockInstallService extends Mock implements InstallService {}

void main() {
  late MockGitHubService mockGitHubService;
  late MockDownloadService mockDownloadService;
  late MockInstallService mockInstallService;

  setUp(() {
    mockGitHubService = MockGitHubService();
    mockDownloadService = MockDownloadService();
    mockInstallService = MockInstallService();

    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'MyBudget',
      packageName: 'fr.jaetan.mybudget',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        gitHubServiceProvider.overrideWithValue(mockGitHubService),
        downloadServiceProvider.overrideWithValue(mockDownloadService),
        installServiceProvider.overrideWithValue(mockInstallService),
      ],
    );
  }

  group('UpdateViewModel - Check for Updates', () {
    final prodRelease = ReleaseInfo(
      version: '1.1.0',
      title: 'Production Update',
      notes: 'Fixes',
      downloadUrl: 'http://url.apk',
      publishedAt: DateTime.now(),
      assetSize: 1000,
      isPrerelease: false,
    );

    final betaRelease = ReleaseInfo(
      version: '1.1.0-beta.1',
      title: 'Beta Update',
      notes: 'Beta features',
      downloadUrl: 'http://beta.apk',
      publishedAt: DateTime.now(),
      assetSize: 1000,
      isPrerelease: true,
    );

    test(
      'Should detect update when current is PROD and newer PROD release exists',
      () async {
        PackageInfo.setMockInitialValues(
          appName: 'MyBudget',
          packageName: 'fr.jaetan.mybudget',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
        );

        when(
          () => mockGitHubService.getReleases(),
        ).thenAnswer((_) async => [prodRelease]);

        final container = makeContainer();
        addTearDown(container.dispose);

        await container.read(updateProvider.notifier).checkForUpdates(null, silent: true);

        final state = container.read(updateProvider);
        expect(state.availableUpdate, isNotNull);
        expect(state.availableUpdate?.version, '1.1.0');
        expect(state.error, isNull);
      },
    );

    test('Should IGNORE beta release when current is PROD', () async {
      PackageInfo.setMockInitialValues(
        appName: 'MyBudget',
        packageName: 'fr.jaetan.mybudget',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );

      when(
        () => mockGitHubService.getReleases(),
      ).thenAnswer((_) async => [betaRelease]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(updateProvider.notifier).checkForUpdates(null, silent: true);
      expect(container.read(updateProvider).availableUpdate, isNull);
    });

    test(
      'Should detect update when current is BETA and newer BETA release exists',
      () async {
        PackageInfo.setMockInitialValues(
          appName: 'MyBudget',
          packageName: 'fr.jaetan.mybudget.beta',
          version: '1.0.0-beta.1',
          buildNumber: '1',
          buildSignature: '',
        );

        final newerBeta = ReleaseInfo(
          version: '1.0.1-beta.1',
          title: 'New Beta',
          notes: '',
          downloadUrl: '',
          publishedAt: DateTime.now(),
          assetSize: 0,
          isPrerelease: true,
        );

        when(
          () => mockGitHubService.getReleases(),
        ).thenAnswer((_) async => [newerBeta]);

        final container = makeContainer();
        addTearDown(container.dispose);

        await container.read(updateProvider.notifier).checkForUpdates(null, silent: true);

        final state = container.read(updateProvider);
        expect(state.availableUpdate, isNotNull);
        expect(state.availableUpdate?.version, '1.0.1-beta.1');
      },
    );

    test('Should handle API errors gracefully', () async {
      when(
        () => mockGitHubService.getReleases(),
      ).thenThrow(Exception('Network Error'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(updateProvider.notifier).checkForUpdates(null, silent: true);

      final state = container.read(updateProvider);
      expect(state.availableUpdate, isNull);
      expect(state.error, contains('Network Error'));
      expect(state.isChecking, false);
    });

    test('Should not propose older version', () async {
      PackageInfo.setMockInitialValues(
        appName: 'MyBudget',
        packageName: 'fr.jaetan.mybudget',
        version: '2.0.0',
        buildNumber: '1',
        buildSignature: '',
      );

      when(
        () => mockGitHubService.getReleases(),
      ).thenAnswer((_) async => [prodRelease]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(updateProvider.notifier).checkForUpdates(null, silent: true);

      expect(container.read(updateProvider).availableUpdate, isNull);
    });

    test(
      'Should find HIGHEST version when multiple beta releases exist',
      () async {
        PackageInfo.setMockInitialValues(
          appName: 'MyBudget',
          packageName: 'fr.jaetan.mybudget.beta',
          version: '1.0.0-beta.1',
          buildNumber: '1',
          buildSignature: '',
        );

        final olderBeta = ReleaseInfo(
          version: '1.0.3-beta.1',
          title: 'Older Beta',
          notes: '',
          downloadUrl: '',
          publishedAt: DateTime.now().subtract(const Duration(days: 5)),
          assetSize: 0,
          isPrerelease: true,
        );

        final middleBeta = ReleaseInfo(
          version: '1.0.5-beta.1',
          title: 'Middle Beta',
          notes: '',
          downloadUrl: '',
          publishedAt: DateTime.now().subtract(const Duration(days: 2)),
          assetSize: 0,
          isPrerelease: true,
        );

        final newestBeta = ReleaseInfo(
          version: '1.0.6-beta.1',
          title: 'Newest Beta',
          notes: '',
          downloadUrl: '',
          publishedAt: DateTime.now().subtract(const Duration(days: 10)),
          assetSize: 0,
          isPrerelease: true,
        );

        when(
          () => mockGitHubService.getReleases(),
        ).thenAnswer((_) async => [middleBeta, olderBeta, newestBeta]);

        final container = makeContainer();
        addTearDown(container.dispose);

        await container.read(updateProvider.notifier).checkForUpdates(null, silent: true);

        final state = container.read(updateProvider);
        expect(state.availableUpdate, isNotNull);
        expect(state.availableUpdate?.version, '1.0.6-beta.1');
      },
    );

    test(
      'Should detect update when current is BETA with -beta.N format',
      () async {
        PackageInfo.setMockInitialValues(
          appName: 'MyBudget',
          packageName: 'fr.jaetan.mybudget.beta',
          version: '1.0.0-beta.2',
          buildNumber: '1',
          buildSignature: '',
        );

        final newerBeta = ReleaseInfo(
          version: '1.0.1-beta.3',
          title: 'New Beta',
          notes: '',
          downloadUrl: '',
          publishedAt: DateTime.now(),
          assetSize: 0,
          isPrerelease: true,
        );

        when(
          () => mockGitHubService.getReleases(),
        ).thenAnswer((_) async => [newerBeta]);

        final container = makeContainer();
        addTearDown(container.dispose);

        await container.read(updateProvider.notifier).checkForUpdates(null, silent: true);

        final state = container.read(updateProvider);
        expect(state.availableUpdate, isNotNull);
        expect(state.currentVersion, '1.0.0-beta.2');
      },
    );

    test(
      'Should find HIGHEST version when multiple prod releases exist',
      () async {
        PackageInfo.setMockInitialValues(
          appName: 'MyBudget',
          packageName: 'fr.jaetan.mybudget',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
        );

        final release103 = ReleaseInfo(
          version: '1.0.3',
          title: 'Release 1.0.3',
          notes: '',
          downloadUrl: '',
          publishedAt: DateTime.now().subtract(const Duration(days: 5)),
          assetSize: 0,
          isPrerelease: false,
        );

        final release105 = ReleaseInfo(
          version: '1.0.5',
          title: 'Release 1.0.5',
          notes: '',
          downloadUrl: '',
          publishedAt: DateTime.now().subtract(const Duration(days: 2)),
          assetSize: 0,
          isPrerelease: false,
        );

        final release106 = ReleaseInfo(
          version: '1.0.6',
          title: 'Release 1.0.6',
          notes: '',
          downloadUrl: '',
          publishedAt: DateTime.now().subtract(const Duration(days: 10)),
          assetSize: 0,
          isPrerelease: false,
        );

        when(
          () => mockGitHubService.getReleases(),
        ).thenAnswer((_) async => [release105, release103, release106]);

        final container = makeContainer();
        addTearDown(container.dispose);

        await container.read(updateProvider.notifier).checkForUpdates(null, silent: true);

        final state = container.read(updateProvider);
        expect(state.availableUpdate, isNotNull);
        expect(state.availableUpdate?.version, '1.0.6');
      },
    );

    test(
      'Should detect update between same base version betas',
      () async {
        PackageInfo.setMockInitialValues(
          appName: 'MyBudget',
          packageName: 'fr.jaetan.mybudget.beta',
          version: '0.4.0-beta.2',
          buildNumber: '1',
          buildSignature: '',
        );

        final newerBeta = ReleaseInfo(
          version: '0.4.0-beta.3',
          title: 'New Beta',
          notes: '',
          downloadUrl: '',
          publishedAt: DateTime.now(),
          assetSize: 0,
          isPrerelease: true,
        );

        when(
          () => mockGitHubService.getReleases(),
        ).thenAnswer((_) async => [newerBeta]);

        final container = makeContainer();
        addTearDown(container.dispose);

        await container.read(updateProvider.notifier).checkForUpdates(null, silent: true);

        final state = container.read(updateProvider);
        expect(state.availableUpdate, isNotNull);
        expect(state.availableUpdate?.version, '0.4.0-beta.3');
      },
    );

    test(
      'Should NOT detect update when current beta is newer',
      () async {
        PackageInfo.setMockInitialValues(
          appName: 'MyBudget',
          packageName: 'fr.jaetan.mybudget.beta',
          version: '0.4.0-beta.3',
          buildNumber: '1',
          buildSignature: '',
        );

        final olderBeta = ReleaseInfo(
          version: '0.4.0-beta.2',
          title: 'Old Beta',
          notes: '',
          downloadUrl: '',
          publishedAt: DateTime.now(),
          assetSize: 0,
          isPrerelease: true,
        );

        when(
          () => mockGitHubService.getReleases(),
        ).thenAnswer((_) async => [olderBeta]);

        final container = makeContainer();
        addTearDown(container.dispose);

        await container.read(updateProvider.notifier).checkForUpdates(null, silent: true);

        expect(container.read(updateProvider).availableUpdate, isNull);
      },
    );
  });
}
