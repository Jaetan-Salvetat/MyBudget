import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:path_provider/path_provider.dart';

class ModelDownloadService {
  static const String modelUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';
  static const String modelFilename = 'gemma-4-E2B-it.litertlm';
  static const String modelDirectory = 'models';
  static const double modelSizeGb = 2.59;
  static const double requiredSpaceGb = 3.0;
  static const String modelVersion = '1.0.0';
  static const String taskGroup = 'gemma_model';

  DownloadTask? _activeTask;

  Future<double> getAvailableSpaceGb() async {
    final diskSpace = DiskSpacePlus();
    final freeMb = await diskSpace.getFreeDiskSpace;
    if (freeMb == null) return 0.0;
    return freeMb / 1024.0;
  }

  bool hasEnoughSpace(double availableGb) => availableGb >= requiredSpaceGb;

  Future<String> get _modelDirectoryPath async {
    final appDir = await getApplicationSupportDirectory();
    return '${appDir.path}/$modelDirectory';
  }

  Future<String> get modelFilePath async {
    final dirPath = await _modelDirectoryPath;
    return '$dirPath/$modelFilename';
  }

  Future<bool> isModelInstalled() async {
    final path = await modelFilePath;
    final file = File(path);
    if (!file.existsSync()) return false;
    final size = await file.length();
    return size > 1000000000;
  }

  Future<TaskRecord?> getActiveDownload() async {
    final records = await FileDownloader()
        .database
        .allRecords(group: taskGroup);
    for (final record in records) {
      if (record.status == TaskStatus.running ||
          record.status == TaskStatus.enqueued ||
          record.status == TaskStatus.waitingToRetry) {
        return record;
      }
    }
    return null;
  }

  Future<void> startDownload({
    required void Function(double progress) onProgress,
    required void Function(String path) onComplete,
    required void Function(String error) onError,
  }) async {
    final dirPath = await _modelDirectoryPath;
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    _activeTask = DownloadTask(
      url: modelUrl,
      filename: modelFilename,
      directory: dirPath,
      baseDirectory: BaseDirectory.root,
      updates: Updates.statusAndProgress,
      retries: 3,
      allowPause: true,
      group: taskGroup,
      displayName: 'Modèle IA Gemma',
    );

    final result = await FileDownloader().download(
      _activeTask!,
      onProgress: onProgress,
      onStatus: (status) {
        if (status == TaskStatus.complete) {
          onComplete('$dirPath/$modelFilename');
        } else if (status == TaskStatus.failed ||
            status == TaskStatus.notFound) {
          onError('Le téléchargement a échoué');
        } else if (status == TaskStatus.canceled) {
          onError('Téléchargement annulé');
        }
      },
    );

    _activeTask = null;

    if (result.status != TaskStatus.complete) {
      throw ModelDownloadException(
        'Téléchargement échoué : ${result.status.name}',
      );
    }
  }

  Future<void> cancelDownload() async {
    final task = _activeTask;
    if (task != null) {
      await FileDownloader().cancel(task);
      _activeTask = null;
      return;
    }
    final record = await getActiveDownload();
    if (record != null) {
      await FileDownloader().cancel(record.task);
    }
  }

  Future<bool> verifyModel(String path) async {
    final file = File(path);
    if (!file.existsSync()) return false;
    final size = await file.length();
    return size > 1000000000;
  }

  Future<void> deleteModel(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}

class ModelDownloadException implements Exception {
  final String message;
  const ModelDownloadException(this.message);

  @override
  String toString() => message;
}
