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

  @override
  LocalModelState build() {
    final status = LocalModelStatus.fromString(
      PreferencesService.getLocalModelStatus(),
    );
    final path = PreferencesService.getLocalModelPath();
    return LocalModelState(status: status, modelPath: path);
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

    await PreferencesService.setLocalModelStatus(
      LocalModelStatus.downloading.name,
    );

    try {
      final path = await _downloadService!.downloadModel(
        onProgress: (progress) {
          state = state.copyWith(downloadProgress: progress);
        },
        onComplete: () {},
        onError: (error) {
          state = state.copyWith(
            status: LocalModelStatus.none,
            error: error,
            downloadProgress: 0.0,
          );
        },
      );

      final isValid = await _downloadService!.verifyModel(path);
      if (!isValid) {
        await _downloadService!.deleteModel(path);
        await PreferencesService.setLocalModelStatus(
          LocalModelStatus.none.name,
        );
        state = state.copyWith(
          status: LocalModelStatus.none,
          error: 'Le modèle téléchargé est corrompu',
          downloadProgress: 0.0,
        );
        return;
      }

      await PreferencesService.setLocalModelStatus(
        LocalModelStatus.ready.name,
      );
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
    } on ModelDownloadException catch (e) {
      await PreferencesService.setLocalModelStatus(
        LocalModelStatus.none.name,
      );
      state = state.copyWith(
        status: LocalModelStatus.none,
        error: e.message,
        downloadProgress: 0.0,
      );
    } catch (e) {
      await PreferencesService.setLocalModelStatus(
        LocalModelStatus.none.name,
      );
      state = state.copyWith(
        status: LocalModelStatus.none,
        error: 'Erreur inattendue : $e',
        downloadProgress: 0.0,
      );
    }
  }

  Future<void> cancelDownload() async {
    _downloadService ??= ModelDownloadService();
    await _downloadService!.cancelDownload();

    await PreferencesService.setLocalModelStatus(LocalModelStatus.none.name);

    state = state.copyWith(
      status: LocalModelStatus.none,
      downloadProgress: 0.0,
    ).clearError();
  }

  Future<void> deleteModel() async {
    await LitertEngineService.resetInstance();

    final path = state.modelPath ?? PreferencesService.getLocalModelPath();
    if (path != null) {
      _downloadService ??= ModelDownloadService();
      await _downloadService!.deleteModel(path);
    }

    await PreferencesService.setLocalModelStatus(LocalModelStatus.none.name);
    await PreferencesService.setLocalModelPath(null);

    ref.invalidate(litertEngineProvider);

    state = const LocalModelState();
  }
}
