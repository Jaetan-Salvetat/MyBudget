import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/services/download_service.dart';
import 'package:mybudget/core/services/github_service.dart';
import 'package:mybudget/core/services/install_service.dart';
import 'package:mybudget/models/release_info_model.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:version/version.dart';

part 'update_provider.g.dart';

// Providers de services overridables pour les tests
final gitHubServiceProvider = Provider<GitHubService>(
  (ref) => GitHubService(),
);
final downloadServiceProvider = Provider<DownloadService>(
  (ref) => DownloadService(),
);
final installServiceProvider = Provider<InstallService>(
  (ref) => InstallService(),
);

class UpdateState {
  final bool isChecking;
  final bool isDownloading;
  final double downloadProgress;
  final ReleaseInfo? availableUpdate;
  final String? error;
  final String? currentVersion;

  const UpdateState({
    this.isChecking = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.availableUpdate,
    this.error,
    this.currentVersion,
  });

  UpdateState copyWith({
    bool? isChecking,
    bool? isDownloading,
    double? downloadProgress,
    ReleaseInfo? availableUpdate,
    String? error,
    String? currentVersion,
  }) {
    return UpdateState(
      isChecking: isChecking ?? this.isChecking,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      availableUpdate: availableUpdate ?? this.availableUpdate,
      error: error ?? this.error,
      currentVersion: currentVersion ?? this.currentVersion,
    );
  }
}

@Riverpod(keepAlive: true)
class UpdateNotifier extends _$UpdateNotifier {
  @override
  UpdateState build() => const UpdateState();

  GitHubService get _gitHubService => ref.read(gitHubServiceProvider);
  DownloadService get _downloadService => ref.read(downloadServiceProvider);
  InstallService get _installService => ref.read(installServiceProvider);

  Future<void> checkForUpdates(
    BuildContext? context, {
    bool silent = false,
  }) async {
    if (state.isChecking) return;

    state = state.copyWith(isChecking: true, error: null);

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final isBeta = packageInfo.packageName.endsWith('.beta');
      final cleanVersion = currentVersion.replaceAll('-beta', '');

      Version currentVersionObj;
      try {
        currentVersionObj = Version.parse(cleanVersion);
      } catch (e) {
        currentVersionObj = Version(1, 0, 0);
      }

      final releases = await _gitHubService.getReleases();

      ReleaseInfo? targetRelease;
      Version? latestVersion;

      for (final release in releases) {
        try {
          final releaseVersion = Version.parse(release.version);
          final matchesType = isBeta ? release.isPrerelease : !release.isPrerelease;

          if (matchesType && releaseVersion > currentVersionObj) {
            if (latestVersion == null || releaseVersion > latestVersion) {
              latestVersion = releaseVersion;
              targetRelease = release;
            }
          }
        } catch (e) {
          continue;
        }
      }

      state = state.copyWith(
        currentVersion: currentVersion,
        availableUpdate: targetRelease,
      );

      if (targetRelease != null) {
        if (context != null && context.mounted) {
          _showUpdateDialog(context);
        }
      } else if (!silent && context != null && context.mounted) {
        FrostedSnackbar.show(context, message: 'Votre application est à jour');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      if (!silent && context != null && context.mounted) {
        FrostedSnackbar.show(context, message: 'Erreur: ${e.toString()}');
      }
    } finally {
      state = state.copyWith(isChecking: false);
    }
  }

  Future<void> downloadAndInstallUpdate(BuildContext context) async {
    if (state.availableUpdate == null) return;

    state = state.copyWith(isDownloading: true, downloadProgress: 0.0);

    if (context.mounted) {
      _showDownloadDialog(context);
    }

    final fileName = 'mybudget-${state.availableUpdate!.version}.apk';

    final filePath = await _downloadService.downloadApk(
      state.availableUpdate!.downloadUrl,
      fileName,
      (progress) {
        state = state.copyWith(downloadProgress: progress);
      },
    );

    if (filePath != null) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      await _installService.installApk(filePath);
    } else {
      if (context.mounted) {
        Navigator.of(context).pop();
        FrostedSnackbar.show(context, message: 'Erreur lors du téléchargement');
      }
    }

    state = state.copyWith(isDownloading: false);
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
            'Une nouvelle version (${state.availableUpdate!.version}) est disponible.',
          ),
          const SizedBox(height: 8),
          const Text(
            'Notes de version :',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Text(state.availableUpdate!.notes),
            ),
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
      content: Builder(
        builder: (context) {
          // Utiliser un Consumer Riverpod ici serait complexe dans ce contexte
          // On garde une approche simple avec un StatefulBuilder
          return StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FrostedLinearProgressIndicator(value: state.downloadProgress),
                  const SizedBox(height: 10),
                  Text('${(state.downloadProgress * 100).toStringAsFixed(0)}%'),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
