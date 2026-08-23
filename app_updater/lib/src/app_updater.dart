import 'package:package_info_plus/package_info_plus.dart';

import 'config/update_config.dart';
import 'models/release_info.dart';
import 'services/download_service.dart';
import 'services/github_service.dart';
import 'services/install_service.dart';
import 'services/version_service.dart';

class AppUpdater {
  final UpdateConfig _config;
  final GitHubService _githubService;
  final VersionService _versionService;
  final DownloadService _downloadService;
  final InstallService _installService;
  final String _currentVersion;

  AppUpdater._({
    required UpdateConfig config,
    required GitHubService githubService,
    required VersionService versionService,
    required DownloadService downloadService,
    required InstallService installService,
    required String currentVersion,
  })  : _config = config,
        _githubService = githubService,
        _versionService = versionService,
        _downloadService = downloadService,
        _installService = installService,
        _currentVersion = currentVersion;

  static Future<AppUpdater> initialize(UpdateConfig config) async {
    final currentVersion = config.currentVersion ??
        (await PackageInfo.fromPlatform()).version;

    final client = config.httpClient;

    return AppUpdater._(
      config: config,
      githubService: GitHubService(
        owner: config.githubOwner,
        repo: config.githubRepo,
        token: config.githubToken,
        client: client,
      ),
      versionService: VersionService(
        comparator: config.versionComparator,
      ),
      downloadService: DownloadService(
        client: client,
        maxRetries: config.maxRetries,
        retryDelay: config.retryDelay,
      ),
      installService: InstallService(),
      currentVersion: currentVersion,
    );
  }

  Future<ReleaseInfo?> checkForUpdates() async {
    final releases = await _githubService.getReleases();
    final filtered = _githubService.filterByChannel(releases, _config.channel);

    ReleaseInfo? best;

    for (final release in filtered) {
      if (!_versionService.isNewer(_currentVersion, release.version)) continue;

      final asset = _resolveAsset(release);
      if (asset == null) continue;

      if (best == null ||
          _versionService.isNewer(best.version, release.version)) {
        best = release;
      }
    }

    return best;
  }

  Stream<double> downloadUpdate(ReleaseInfo release) {
    final asset = _resolveAsset(release);
    if (asset == null) {
      throw ArgumentError('No suitable APK asset found in release');
    }
    final fileName = DownloadService.fileNameFromUrl(asset.downloadUrl);
    return _downloadService.downloadFile(asset.downloadUrl, fileName);
  }

  Future<void> installUpdate(String filePath) async {
    await _installService.installApk(filePath);
  }

  String get currentVersion => _currentVersion;

  UpdateConfig get config => _config;

  ReleaseAsset? _resolveAsset(ReleaseInfo release) {
    if (_config.assetSelector != null) {
      return _config.assetSelector!(release.assets);
    }
    return release.defaultApkAsset;
  }
}
