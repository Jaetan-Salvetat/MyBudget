import 'package:mybudget/core/enums/gemini_nano_failure.dart';

sealed class GeminiNanoDownload {
  const GeminiNanoDownload();
}

final class GeminiNanoDownloadStarted extends GeminiNanoDownload {
  const GeminiNanoDownloadStarted({required this.totalBytes});

  final int totalBytes;
}

final class GeminiNanoDownloadProgress extends GeminiNanoDownload {
  const GeminiNanoDownloadProgress({
    required this.downloadedBytes,
    required this.totalBytes,
  });

  final int downloadedBytes;
  final int totalBytes;

  double? get ratio {
    if (totalBytes <= 0) return null;
    return (downloadedBytes / totalBytes).clamp(0, 1).toDouble();
  }
}

final class GeminiNanoDownloadCompleted extends GeminiNanoDownload {
  const GeminiNanoDownloadCompleted();
}

final class GeminiNanoDownloadFailed extends GeminiNanoDownload {
  const GeminiNanoDownloadFailed(this.failure);

  final GeminiNanoFailure failure;
}
