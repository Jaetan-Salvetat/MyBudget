sealed class ScanException implements Exception {
  static const int scanCooldownSeconds = 120;

  final String message;
  final int retryAfterSeconds;

  const ScanException({
    required this.message,
    required this.retryAfterSeconds,
  });
}

final class ScanCooldownException extends ScanException {
  const ScanCooldownException({required super.retryAfterSeconds})
      : super(
          message: 'Veuillez patienter avant de relancer un scan',
        );
}

final class ScanRateLimitException extends ScanException {
  const ScanRateLimitException()
      : super(
          message: 'Le service d\'analyse est temporairement surchargé',
          retryAfterSeconds: ScanException.scanCooldownSeconds,
        );
}

final class ScanGenericException extends ScanException {
  final String details;

  const ScanGenericException({required this.details})
      : super(
          message: 'Impossible d\'analyser le ticket',
          retryAfterSeconds: 0,
        );
}
