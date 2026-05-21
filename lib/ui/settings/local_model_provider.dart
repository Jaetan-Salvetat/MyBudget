import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:mybudget/core/enums/local_model_status.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/litert_engine_service.dart';
import 'package:mybudget/core/services/model_download_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_model_provider.g.dart';

class LocalModelState {
  final LocalModelStatus status;
  final double downloadProgress;
  final String? error;
  final double? availableSpaceGb;
  final String? modelPath;

  const LocalModelState({
    this.status = LocalModelStatus.none,
    this.downloadProgress = 0.0,
    this.error,
    this.availableSpaceGb,
    this.modelPath,
  });

  LocalModelState copyWith({
    LocalModelStatus? status,
    double? downloadProgress,
    String? error,
    double? availableSpaceGb,
    String? modelPath,
  }) {
    return LocalModelState(
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      error: error ?? this.error,
      availableSpaceGb: availableSpaceGb ?? this.availableSpaceGb,
      modelPath: modelPath ?? this.modelPath,
    );
  }

  LocalModelState clearError() {
    return LocalModelState(
      status: status,
      downloadProgress: downloadProgress,
      availableSpaceGb: availableSpaceGb,
      modelPath: modelPath,
    );
  }
}

@Riverpod(keepAlive: true)
class LocalModelNotifier extends _$LocalModelNotifier {
  ModelDownloadService? _downloadService;
  StreamSubscription<TaskRecord>? _dbSubscription;

  @override
  LocalModelState build() {
    final path = PreferencesService.getLocalModelPath();
    final initialStatus =
        path != null ? LocalModelStatus.ready : LocalModelStatus.none;

    ref.onDispose(() => _dbSubscription?.cancel());

    _resolveStatus();

    return LocalModelState(status: initialStatus, modelPath: path);
  }

  Future<void> _resolveStatus() async {
    _downloadService ??= ModelDownloadService();

    final isInstalled = await _downloadService!.isModelInstalled();
    if (isInstalled) {
      final path = await _downloadService!.modelFilePath;
      if (state.modelPath != path) {
        await PreferencesService.setLocalModelPath(path);
      }
      state = state.copyWith(
        status: LocalModelStatus.ready,
        modelPath: path,
      );
      return;
    }

    final activeRecord = await _downloadService!.getActiveDownload();
    if (activeRecord != null) {
      state = state.copyWith(
        status: LocalModelStatus.downloading,
        downloadProgress: activeRecord.progress,
      );
      _listenToWorkerUpdates();
      return;
    }

    if (state.status != LocalModelStatus.none) {
      await PreferencesService.setLocalModelPath(null);
      state = const LocalModelState();
    }
  }

  void _listenToWorkerUpdates() {
    _dbSubscription?.cancel();
    _dbSubscription = FileDownloader()
        .database
        .updates
        .where((record) => record.group == ModelDownloadService.taskGroup)
        .listen(_onWorkerUpdate);
  }

  void _onWorkerUpdate(TaskRecord record) {
    state = state.copyWith(downloadProgress: record.progress);

    if (record.status == TaskStatus.complete) {
      _onDownloadComplete();
    } else if (record.status == TaskStatus.failed ||
        record.status == TaskStatus.notFound) {
      state = state.copyWith(
        status: LocalModelStatus.none,
        error: 'Le téléchargement a échoué',
        downloadProgress: 0.0,
      );
      _dbSubscription?.cancel();
    } else if (record.status == TaskStatus.canceled) {
      state = state.copyWith(
        status: LocalModelStatus.none,
        downloadProgress: 0.0,
      ).clearError();
      _dbSubscription?.cancel();
    }
  }

  Future<void> _onDownloadComplete() async {
    _dbSubscription?.cancel();
    _downloadService ??= ModelDownloadService();

    final path = await _downloadService!.modelFilePath;
    final isValid = await _downloadService!.verifyModel(path);

    if (!isValid) {
      await _downloadService!.deleteModel(path);
      await PreferencesService.setLocalModelPath(null);
      state = state.copyWith(
        status: LocalModelStatus.none,
        error: 'Le modèle téléchargé est corrompu',
        downloadProgress: 0.0,
      );
      return;
    }

    await PreferencesService.setLocalModelPath(path);
    await PreferencesService.setLocalModelVersion(
      ModelDownloadService.modelVersion,
    );

    state = state.copyWith(
      status: LocalModelStatus.ready,
      modelPath: path,
      downloadProgress: 1.0,
    );

    ref.invalidate(litertEngineProvider);
  }

  Future<void> checkDiskSpace() async {
    _downloadService ??= ModelDownloadService();
    final space = await _downloadService!.getAvailableSpaceGb();
    state = state.copyWith(availableSpaceGb: space);
  }

  Future<void> startDownload() async {
    if (state.status == LocalModelStatus.downloading) return;

    _downloadService ??= ModelDownloadService();

    final space = await _downloadService!.getAvailableSpaceGb();
    if (!_downloadService!.hasEnoughSpace(space)) {
      state = state.copyWith(
        error: 'Espace insuffisant (${space.toStringAsFixed(1)} Go disponible, '
            '${ModelDownloadService.requiredSpaceGb} Go requis)',
      );
      return;
    }

    state = state.copyWith(
      status: LocalModelStatus.downloading,
      downloadProgress: 0.0,
    ).clearError();

    _listenToWorkerUpdates();

    try {
      await _downloadService!.startDownload(
        onProgress: (progress) {
          state = state.copyWith(downloadProgress: progress);
        },
        onComplete: (_) {},
        onError: (error) {
          state = state.copyWith(
            status: LocalModelStatus.none,
            error: error,
            downloadProgress: 0.0,
          );
        },
      );

      await _onDownloadComplete();
    } on ModelDownloadException catch (e) {
      state = state.copyWith(
        status: LocalModelStatus.none,
        error: e.message,
        downloadProgress: 0.0,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        status: LocalModelStatus.none,
        error: 'Erreur inattendue : $e',
        downloadProgress: 0.0,
      );
      rethrow;
    }
  }

  Future<void> cancelDownload() async {
    try {
      _downloadService ??= ModelDownloadService();
      await _downloadService!.cancelDownload();
      _dbSubscription?.cancel();

      state = state.copyWith(
        status: LocalModelStatus.none,
        downloadProgress: 0.0,
      ).clearError();
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de l\'annulation : $e');
      rethrow;
    }
  }

  Future<void> deleteModel() async {
    try {
      await LitertEngineService.resetInstance();

      final path = state.modelPath ?? PreferencesService.getLocalModelPath();
      if (path != null) {
        _downloadService ??= ModelDownloadService();
        await _downloadService!.deleteModel(path);
      }

      await PreferencesService.setLocalModelPath(null);

      ref.invalidate(litertEngineProvider);

      state = const LocalModelState();
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la suppression : $e');
      rethrow;
    }
  }
}
