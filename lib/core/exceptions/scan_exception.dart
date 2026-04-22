sealed class ScanException implements Exception {
  static const int scanCooldownSeconds = 120;

  final String message;
  final int retryAfterSeconds;

  const ScanException({
    required this.message,
    required this.retryAfterSeconds,
  });

  static ScanException fromServerMessage(String serverMessage) {
    final upper = serverMessage.toUpperCase();

    if (upper.contains('429') || upper.contains('RESOURCE_EXHAUSTED')) {
      return const ScanRateLimitException();
    }
    if (upper.contains('503') || upper.contains('UNAVAILABLE')) {
      return const ScanServiceUnavailableException();
    }
    if (upper.contains('500') || upper.contains('INTERNAL')) {
      return const ScanGenericException(
        message: 'Une erreur interne est survenue côté serveur',
      );
    }
    if (upper.contains('504') || upper.contains('DEADLINE_EXCEEDED')) {
      return const ScanGenericException(
        message: 'L\'analyse a pris trop de temps, veuillez réessayer',
      );
    }
    if (upper.contains('403') || upper.contains('PERMISSION_DENIED')) {
      return const ScanGenericException(
        message: 'Accès refusé au service d\'analyse',
      );
    }
    if (upper.contains('404') || upper.contains('NOT_FOUND')) {
      return const ScanGenericException(
        message: 'Le service d\'analyse est indisponible',
      );
    }
    if (upper.contains('400') || upper.contains('INVALID_ARGUMENT')) {
      return const ScanGenericException(
        message: 'L\'image envoyée n\'a pas pu être traitée',
      );
    }

    return const ScanGenericException(
      message: 'Impossible d\'analyser le ticket',
    );
  }
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

final class ScanServiceUnavailableException extends ScanException {
  const ScanServiceUnavailableException()
      : super(
          message: 'Le service d\'analyse est momentanément indisponible',
          retryAfterSeconds: ScanException.scanCooldownSeconds,
        );
}

final class ScanGenericException extends ScanException {
  const ScanGenericException({
    required super.message,
  }) : super(
          retryAfterSeconds: 0,
        );
}
