import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DownloadService {
  Future<String?> downloadApk(
    String url,
    String fileName,
    Function(double) onProgress,
  ) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      final contentLength = response.contentLength ?? 0;
      int downloaded = 0;

      final apkDirectory = await getExternalStorageDirectory();
      if (apkDirectory == null) return null;

      final filePath = p.join(apkDirectory.path, fileName);
      final file = File(filePath);

      final sink = file.openWrite();

      await response.stream.forEach((chunk) {
        sink.add(chunk);
        downloaded += chunk.length;
        onProgress(downloaded / contentLength);
      });

      await sink.flush();
      await sink.close();

      return filePath;
    } catch (e) {
      return null;
    }
  }
}
