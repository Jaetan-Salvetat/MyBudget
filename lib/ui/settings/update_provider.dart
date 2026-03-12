import 'dart:async';

import 'package:app_updater/app_updater.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'update_provider.g.dart';

class UpdateState {
  final bool isChecking;
  final bool isDownloading;
  final double downloadProgress;
  final ReleaseInfo? availableUpdate;
  final String? error;
  final String? currentVersion;
  final String? downloadedFilePath;

  const UpdateState({
    this.isChecking = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.availableUpdate,
    this.error,
    this.currentVersion,
    this.downloadedFilePath,
  });

  UpdateState copyWith({
    bool? isChecking,
    bool? isDownloading,
    double? downloadProgress,
    ReleaseInfo? availableUpdate,
    String? error,
    String? currentVersion,
    String? downloadedFilePath,
  }) {
    return UpdateState(
      isChecking: isChecking ?? this.isChecking,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      availableUpdate: availableUpdate ?? this.availableUpdate,
      error: error ?? this.error,
      currentVersion: currentVersion ?? this.currentVersion,
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,
    );
  }
}

@Riverpod(keepAlive: true)
class UpdateNotifier extends _$UpdateNotifier {
  @override
  UpdateState build() {
    final updater = ref.watch(appUpdaterProvider);
    return UpdateState(currentVersion: updater.currentVersion);
  }

  AppUpdater get _updater => ref.read(appUpdaterProvider);

  Future<void> checkForUpdates({bool silent = false}) async {
    if (state.isChecking) return;

    state = state.copyWith(isChecking: true, error: null);

    try {
      final release = await _updater.checkForUpdates();
      state = state.copyWith(availableUpdate: release);
    } on UpdateException catch (e) {
      state = state.copyWith(error: _formatError(e));
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isChecking: false);
    }
  }

  Future<void> downloadUpdate() async {
    final release = state.availableUpdate;
    if (release == null || state.isDownloading) return;

    state = state.copyWith(isDownloading: true, downloadProgress: 0.0, error: null);

    try {
      final stream = _updater.downloadUpdate(release);
      await for (final progress in stream) {
        state = state.copyWith(downloadProgress: progress);
      }

      final asset = release.defaultApkAsset;
      if (asset != null) {
        final dir = await getExternalStorageDirectory();
        if (dir != null) {
          final fileName = _fileNameFromUrl(asset.downloadUrl);
          final filePath = '${dir.path}/updates/$fileName';
          state = state.copyWith(downloadedFilePath: filePath);
          await _updater.installUpdate(filePath);
        }
      }
    } on UpdateException catch (e) {
      state = state.copyWith(error: _formatError(e));
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isDownloading: false);
    }
  }

  String _fileNameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.pathSegments.isEmpty) return 'update.apk';
    final last = uri.pathSegments.last;
    return last.endsWith('.apk') ? last : 'update.apk';
  }

  String _formatError(UpdateException e) {
    return switch (e) {
      NetworkException() => 'Erreur réseau. Vérifiez votre connexion.',
      GitHubApiException() => 'Erreur serveur (${e.statusCode}).',
      DownloadException() => 'Échec du téléchargement après ${e.attempts} tentatives.',
      InstallException() => 'Erreur lors de l\'installation.',
      VersionParseException() => 'Version invalide détectée.',
    };
  }
}
