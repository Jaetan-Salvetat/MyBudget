import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:version/version.dart';
import 'package:mybudget/models/release_info_model.dart';
import 'package:mybudget/core/services/github_service.dart';
import 'package:mybudget/core/services/download_service.dart';
import 'package:mybudget/core/services/install_service.dart';
import 'package:frosted_ui/frosted_ui.dart';

class UpdateViewModel extends ChangeNotifier {
  final GitHubService _gitHubService = GitHubService();
  final DownloadService _downloadService = DownloadService();
  final InstallService _installService = InstallService();

  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  ReleaseInfo? _availableUpdate;
  String? _error;
  String? _currentVersion;

  bool get isChecking => _isChecking;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  ReleaseInfo? get availableUpdate => _availableUpdate;
  String? get error => _error;
  String? get currentVersion => _currentVersion;

  Future<void> checkForUpdates(
    BuildContext context, {
    bool silent = false,
  }) async {
    if (_isChecking) return;

    _isChecking = true;
    _error = null;
    notifyListeners();

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;

      // Determine if current app is Beta
      // Beta versions usually have a build name suffix or we check if version contains "beta".
      // However, standard Flutter version string is X.Y.Z.
      // We can rely on the package name suffix or build signature, but for now, let's assume
      // we detect beta if the version string from packageInfo implies it (it might not on Android if versionName is simple).
      // A more robust way: check package name.
      final isBeta = packageInfo.packageName.endsWith('.beta');

      // We need to handle version parsing carefully.
      // version package parses semantic versions.
      // If currentVersion is "1.0.0", Version.parse works.
      // If "1.0.0-beta", it works.

      Version currentVersionObj;
      try {
        currentVersionObj = Version.parse(_currentVersion!);
      } catch (e) {
        // Fallback if version is not standard
        currentVersionObj = Version(1, 0, 0);
      }

      final releases = await _gitHubService.getReleases();

      ReleaseInfo? targetRelease;

      for (final release in releases) {
        try {
          final releaseVersion = Version.parse(release.version);

          if (isBeta) {
            // Beta Channel: Only update to newer Beta (prerelease: true)
            if (release.isPrerelease && release.version.contains('beta')) {
              if (releaseVersion > currentVersionObj) {
                targetRelease = release;
                break; // Found the latest applicable beta (assuming list is sorted by date desc from GitHub)
              }
            }
          } else {
            // Prod Channel: Only update to newer Prod (prerelease: false)
            if (!release.isPrerelease) {
              if (releaseVersion > currentVersionObj) {
                targetRelease = release;
                break;
              }
            }
          }
        } catch (e) {
          continue; // Skip malformed versions
        }
      }

      if (targetRelease != null) {
        _availableUpdate = targetRelease;
        if (context.mounted) {
          _showUpdateDialog(context);
        }
      } else if (!silent && context.mounted) {
        FrostedSnackbar.show(context, message: "Votre application est à jour");
      }
    } catch (e) {
      _error = e.toString();
      if (!silent && context.mounted) {
        FrostedSnackbar.show(context, message: "Erreur: $_error");
      }
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<void> downloadAndInstallUpdate(BuildContext context) async {
    if (_availableUpdate == null) return;

    _isDownloading = true;
    _downloadProgress = 0.0;
    notifyListeners();

    // Show progress dialog
    if (context.mounted) {
      _showDownloadDialog(context);
    }

    final fileName = 'mybudget-${_availableUpdate!.version}.apk';

    final filePath = await _downloadService.downloadApk(
      _availableUpdate!.downloadUrl,
      fileName,
      (progress) {
        _downloadProgress = progress;
        notifyListeners();
      },
    );

    if (filePath != null) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close download dialog
      }
      await _installService.installApk(filePath);
    } else {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close download dialog
        FrostedSnackbar.show(context, message: "Erreur lors du téléchargement");
      }
    }

    _isDownloading = false;
    notifyListeners();
  }

  void _showUpdateDialog(BuildContext context) {
    FrostedDialog.show(
      context: context,
      title: const Text('Mise à jour disponible'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Une nouvelle version (${_availableUpdate!.version}) est disponible.',
          ),
          const SizedBox(height: 8),
          const Text(
            'Notes de version :',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(child: Text(_availableUpdate!.notes)),
          ),
        ],
      ),
      actions: [
        FrostedTonalButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Plus tard'),
        ),
        FrostedFilledButton(
          onPressed: () {
            Navigator.pop(context);
            downloadAndInstallUpdate(context);
          },
          child: const Text('Télécharger'),
        ),
      ],
    );
  }

  void _showDownloadDialog(BuildContext context) {
    FrostedDialog.show(
      context: context,
      title: const Text('Téléchargement...'),
      content: Consumer<UpdateViewModel>(
        builder: (context, vm, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FrostedLinearProgressIndicator(value: vm.downloadProgress),
              const SizedBox(height: 10),
              Text('${(vm.downloadProgress * 100).toStringAsFixed(0)}%'),
            ],
          );
        },
      ),
    );
  }
}
