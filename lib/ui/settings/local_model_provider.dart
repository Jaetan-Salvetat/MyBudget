import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:mybudget/core/constants/local_model_catalog.dart';
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
  final String? modelId;

  const LocalModelState({
    this.status = LocalModelStatus.none,
    this.downloadProgress = 0.0,
    this.error,
    this.availableSpaceGb,
    this.modelPath,
    this.modelId,
  });

  LocalModelConfig? get installedModel =>
      modelId != null ? LocalModelCatalog.getById(modelId!) : null;

  LocalModelState copyWith({
    LocalModelStatus? status,
    double? downloadProgress,
    String? error,
    double? availableSpaceGb,
    String? modelPath,
    String? modelId,
  }) {
    return LocalModelState(
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      error: error ?? this.error,
      availableSpaceGb: availableSpaceGb ?? this.availableSpaceGb,
      modelPath: modelPath ?? this.modelPath,
      modelId: modelId ?? this.modelId,
    );
  }

  LocalModelState clearError() {
    return LocalModelState(
      status: status,
      downloadProgress: downloadProgress,
      availableSpaceGb: availableSpaceGb,
      modelPath: modelPath,
      modelId: modelId,
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
    final modelId = PreferencesService.getLocalModelId();
    final initialStatus =
        path != null ? LocalModelStatus.ready : LocalModelStatus.none;

    ref.onDispose(() => _dbSubscription?.cancel());

    Future.microtask(_resolveStatus);

    return LocalModelState(
      status: initialStatus,
      modelPath: path,
      modelId: modelId,
    );
  }

  Future<void> _resolveStatus() async {
    _downloadService ??= ModelDownloadService();
    final modelId = state.modelId;
    final config = modelId != null ? LocalModelCatalog.getById(modelId) : null;

    if (config != null) {
      final isInstalled = await _downloadService!.isModelInstalled(config);
      if (isInstalled) {
        final path = await _downloadService!.modelFilePath(config);
        if (state.modelPath != path) {
          await PreferencesService.setLocalModelPath(path);
        }
        state = state.copyWith(
          status: LocalModelStatus.ready,
          modelPath: path,
        );
        return;
      }

      final activeRecord = await _downloadService!.getActiveDownload(config);
      if (activeRecord != null) {
        state = state.copyWith(
          status: LocalModelStatus.downloading,
          downloadProgress: activeRecord.progress,
        );
        _listenToWorkerUpdates(config);
        return;
      }
    }

    for (final candidate in LocalModelCatalog.models) {
      final activeRecord =
          await _downloadService!.getActiveDownload(candidate);
      if (activeRecord != null) {
        await PreferencesService.setLocalModelId(candidate.id);
        state = state.copyWith(
          status: LocalModelStatus.downloading,
          downloadProgress: activeRecord.progress,
          modelId: candidate.id,
        );
        _listenToWorkerUpdates(candidate);
        return;
      }
    }

    if (state.status != LocalModelStatus.none) {
      await PreferencesService.setLocalModelPath(null);
      await PreferencesService.setLocalModelId(null);
      state = const LocalModelState();
    }
  }

  void _listenToWorkerUpdates(LocalModelConfig config) {
    _dbSubscription?.cancel();
    _dbSubscription = FileDownloader()
        .database
        .updates
        .where((record) => record.group == config.taskGroup)
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

    final config = state.installedModel;
    if (config == null) return;

    final path = await _downloadService!.modelFilePath(config);
    final isValid = await _downloadService!.verifyModel(path);

    if (!isValid) {
      await _downloadService!.deleteModel(path);
      await PreferencesService.setLocalModelPath(null);
      await PreferencesService.setLocalModelId(null);
      state = state.copyWith(
        status: LocalModelStatus.none,
        error: 'Le modèle téléchargé est corrompu',
        downloadProgress: 0.0,
        modelId: null,
      );
      return;
    }

    await PreferencesService.setLocalModelPath(path);
    await PreferencesService.setLocalModelVersion(config.version);

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

  Future<void> startDownload(LocalModelConfig config) async {
    if (state.status == LocalModelStatus.downloading) return;

    _downloadService ??= ModelDownloadService();

    final space = await _downloadService!.getAvailableSpaceGb();
    if (space < config.requiredSpaceGb) {
      state = state.copyWith(
        error: 'Espace insuffisant (${space.toStringAsFixed(1)} Go disponible, '
            '${config.requiredSpaceGb} Go requis)',
      );
      return;
    }

    await PreferencesService.setLocalModelId(config.id);

    state = state.copyWith(
      status: LocalModelStatus.downloading,
      downloadProgress: 0.0,
      modelId: config.id,
    ).clearError();

    _listenToWorkerUpdates(config);

    try {
      await _downloadService!.enqueueDownload(config);
    } catch (e) {
      _dbSubscription?.cancel();
      await PreferencesService.setLocalModelId(null);
      state = state.copyWith(
        status: LocalModelStatus.none,
        error: 'Erreur inattendue : $e',
        downloadProgress: 0.0,
        modelId: null,
      );
      rethrow;
    }
  }

  Future<void> cancelDownload() async {
    try {
      _downloadService ??= ModelDownloadService();
      final config = state.installedModel;
      if (config != null) {
        await _downloadService!.cancelDownload(config);
      }
      _dbSubscription?.cancel();

      await PreferencesService.setLocalModelId(null);

      state = const LocalModelState().copyWith(
        availableSpaceGb: state.availableSpaceGb,
      );
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
      await PreferencesService.setLocalModelId(null);

      ref.invalidate(litertEngineProvider);

      state = const LocalModelState();
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la suppression : $e');
      rethrow;
    }
  }
}
