import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/services/download_service.dart';
import 'package:mybudget/core/services/github_service.dart';
import 'package:mybudget/core/services/install_service.dart';
import 'package:mybudget/models/release_info_model.dart';
import 'package:mybudget/ui/settings/update_viewmodel.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGitHubService extends Mock implements GitHubService {}

class MockDownloadService extends Mock implements DownloadService {}

class MockInstallService extends Mock implements InstallService {}

void main() {
  late UpdateViewModel viewModel;
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

    viewModel = UpdateViewModel(
      gitHubService: mockGitHubService,
      downloadService: mockDownloadService,
      installService: mockInstallService,
    );
  });

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

        await viewModel.checkForUpdates(null, silent: true);

        expect(viewModel.availableUpdate, isNotNull);
        expect(viewModel.availableUpdate?.version, '1.1.0');
        expect(viewModel.error, isNull);
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

      await viewModel.checkForUpdates(null, silent: true);
      expect(viewModel.availableUpdate, isNull);
    });

    test(
      'Should detect update when current is BETA and newer BETA release exists',
      () async {
        PackageInfo.setMockInitialValues(
          appName: 'MyBudget',
          packageName: 'fr.jaetan.mybudget.beta',
          version: '1.0.0-beta',
          buildNumber: '1',
          buildSignature: '',
        );

        final newerBeta = ReleaseInfo(
          version: '1.0.1-beta',
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

        await viewModel.checkForUpdates(null, silent: true);

        expect(viewModel.availableUpdate, isNotNull);
        expect(viewModel.availableUpdate?.version, '1.0.1-beta');
      },
    );

    test('Should handle API errors gracefully', () async {
      when(
        () => mockGitHubService.getReleases(),
      ).thenThrow(Exception('Network Error'));

      await viewModel.checkForUpdates(null, silent: true);

      expect(viewModel.availableUpdate, isNull);
      expect(viewModel.error, contains('Network Error'));
      expect(viewModel.isChecking, false);
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

      await viewModel.checkForUpdates(null, silent: true);

      expect(viewModel.availableUpdate, isNull);
    });
  });
}
