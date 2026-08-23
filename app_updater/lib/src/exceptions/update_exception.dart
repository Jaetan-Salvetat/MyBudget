sealed class UpdateException implements Exception {
  final String message;

  const UpdateException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkException extends UpdateException {
  const NetworkException([super.message = 'Network error']);
}

final class GitHubApiException extends UpdateException {
  final int statusCode;

  const GitHubApiException({
    required this.statusCode,
    String message = 'GitHub API error',
  }) : super(message);

  @override
  String toString() => 'GitHubApiException($statusCode): $message';
}

final class DownloadException extends UpdateException {
  final String url;
  final int attempts;

  const DownloadException({
    required this.url,
    required this.attempts,
    String message = 'Download failed',
  }) : super(message);

  @override
  String toString() =>
      'DownloadException: $message (url: $url, attempts: $attempts)';
}

final class InstallException extends UpdateException {
  final String filePath;

  const InstallException({
    required this.filePath,
    String message = 'Installation failed',
  }) : super(message);

  @override
  String toString() => 'InstallException: $message (file: $filePath)';
}

final class VersionParseException extends UpdateException {
  final String version;

  const VersionParseException({
    required this.version,
    String message = 'Failed to parse version',
  }) : super(message);

  @override
  String toString() => 'VersionParseException: $message ($version)';
}
