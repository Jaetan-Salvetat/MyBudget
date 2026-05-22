import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:mybudget/core/constants/local_model_catalog.dart';
import 'package:path_provider/path_provider.dart';

class ModelDownloadService {
  static const String modelDirectory = 'models';

  Future<double> getAvailableSpaceGb() async {
    final diskSpace = DiskSpacePlus();
    final freeMb = await diskSpace.getFreeDiskSpace;
    if (freeMb == null) return 0.0;
    return freeMb / 1024.0;
  }

  Future<String> get _modelDirectoryPath async {
    final appDir = await getApplicationSupportDirectory();
    return '${appDir.path}/$modelDirectory';
  }

  Future<String> modelFilePath(LocalModelConfig config) async {
    final dirPath = await _modelDirectoryPath;
    return '$dirPath/${config.filename}';
  }

  Future<bool> isModelInstalled(LocalModelConfig config) async {
    final path = await modelFilePath(config);
    final file = File(path);
    if (!file.existsSync()) return false;
    final size = await file.length();
    return size > 1000000000;
  }

  Future<TaskRecord?> getActiveDownload(LocalModelConfig config) async {
    final records =
        await FileDownloader().database.allRecords(group: config.taskGroup);
    for (final record in records) {
      if (record.status == TaskStatus.running ||
          record.status == TaskStatus.enqueued ||
          record.status == TaskStatus.waitingToRetry ||
          record.status == TaskStatus.paused) {
        return record;
      }
    }
    return null;
  }

  Future<void> enqueueDownload(LocalModelConfig config) async {
    final dirPath = await _modelDirectoryPath;
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final task = DownloadTask(
      url: config.url,
      filename: config.filename,
      directory: dirPath,
      baseDirectory: BaseDirectory.root,
      updates: Updates.statusAndProgress,
      retries: 3,
      allowPause: true,
      group: config.taskGroup,
      displayName: config.displayName,
    );

    await FileDownloader().enqueue(task);
  }

  Future<void> cancelDownload(LocalModelConfig config) async {
    final record = await getActiveDownload(config);
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
