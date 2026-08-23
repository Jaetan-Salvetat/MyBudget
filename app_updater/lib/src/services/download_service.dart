import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../exceptions/update_exception.dart';

class DownloadService {
  final http.Client _client;
  final int _maxRetries;
  final Duration _retryDelay;

  DownloadService({
    http.Client? client,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  })  : _client = client ?? http.Client(),
        _maxRetries = maxRetries,
        _retryDelay = retryDelay;

  Stream<double> downloadFile(String url, String fileName) {
    final controller = StreamController<double>();

    _download(url, fileName, controller).then((_) {
      if (!controller.isClosed) controller.close();
    }).catchError((Object error) {
      if (!controller.isClosed) {
        controller.addError(error);
        controller.close();
      }
    });

    return controller.stream;
  }

  Future<void> _download(
    String url,
    String fileName,
    StreamController<double> controller,
  ) async {
    final dir = await _getDownloadDirectory();
    final destinationPath = p.join(dir, fileName);
    final tmpPath = '$destinationPath.tmp';

    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        await _attemptDownload(url, tmpPath, controller);
        final tmpFile = File(tmpPath);
        await tmpFile.rename(destinationPath);
        return;
      } catch (e) {
        final tmpFile = File(tmpPath);
        if (await tmpFile.exists()) {
          await tmpFile.delete();
        }

        if (attempt == _maxRetries) {
          throw DownloadException(
            url: url,
            attempts: _maxRetries,
            message: e.toString(),
          );
        }

        final delay = _retryDelay * (1 << (attempt - 1));
        await Future<void>.delayed(delay);
      }
    }
  }

  Future<void> _attemptDownload(
    String url,
    String tmpPath,
    StreamController<double> controller,
  ) async {
    final request = http.Request('GET', Uri.parse(url));
    final http.StreamedResponse response;

    try {
      response = await _client.send(request);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    }

    if (response.statusCode != 200) {
      throw DownloadException(
        url: url,
        attempts: 1,
        message: 'HTTP ${response.statusCode}',
      );
    }

    final totalBytes = response.contentLength ?? -1;
    var receivedBytes = 0;

    final file = File(tmpPath);
    final sink = file.openWrite();

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        if (totalBytes > 0 && !controller.isClosed) {
          controller.add(receivedBytes / totalBytes);
        }
      }
    } finally {
      await sink.close();
    }
  }

  Future<String> _getDownloadDirectory() async {
    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw const DownloadException(
        url: '',
        attempts: 0,
        message: 'External storage not available',
      );
    }
    final updatesDir = Directory(p.join(dir.path, 'updates'));
    if (!await updatesDir.exists()) {
      await updatesDir.create(recursive: true);
    }
    return updatesDir.path;
  }

  static String fileNameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return 'update.apk';
    final segments = uri.pathSegments;
    if (segments.isEmpty) return 'update.apk';
    final last = segments.last;
    return last.endsWith('.apk') ? last : 'update.apk';
  }
}
