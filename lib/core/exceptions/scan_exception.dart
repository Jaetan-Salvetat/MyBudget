import 'package:mybudget/core/enums/ai_request_failure.dart';

sealed class ScanException implements Exception {
  static const int scanCooldownSeconds = 120;

  final String message;
  final int retryAfterSeconds;

  const ScanException({required this.message, required this.retryAfterSeconds});

  /// Traduit l'échec typé du client en une erreur que l'écran sait montrer :
  /// un message, et surtout ce que l'utilisateur peut faire ensuite.
  static ScanException fromFailure(AiRequestFailure failure) {
    return switch (failure) {
      AiRequestFailure.invalidKey ||
      AiRequestFailure.permissionDenied ||
      AiRequestFailure.modelNotFound => const ScanInvalidApiKeyException(),
      AiRequestFailure.quotaExceeded => const ScanRateLimitException(),
      AiRequestFailure.serviceUnavailable =>
        const ScanServiceUnavailableException(),
      AiRequestFailure.timeout => const ScanGenericException(
        message: 'L\'analyse a pris trop de temps, veuillez réessayer',
      ),
      AiRequestFailure.offline => const ScanOfflineException(),
      AiRequestFailure.malformedResponse => const ScanGenericException(
        message: 'La réponse du service n\'a pas pu être lue',
      ),
      AiRequestFailure.unknown => const ScanGenericException(
        message: 'Impossible d\'analyser le ticket',
      ),
    };
  }
}

final class ScanCooldownException extends ScanException {
  const ScanCooldownException({required super.retryAfterSeconds})
    : super(message: 'Veuillez patienter avant de relancer un scan');
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

final class ScanMissingApiKeyException extends ScanException {
  const ScanMissingApiKeyException()
    : super(
        message: 'Le scan de ticket demande votre propre clé API',
        retryAfterSeconds: 0,
      );
}

/// La clé est bien là mais le fournisseur la refuse : réessayer ne changera
/// rien, il faut en poser une autre.
final class ScanInvalidApiKeyException extends ScanException {
  const ScanInvalidApiKeyException()
    : super(
        message: 'Votre clé API a été refusée par le fournisseur',
        retryAfterSeconds: 0,
      );
}

final class ScanOfflineException extends ScanException {
  const ScanOfflineException()
    : super(message: 'Pas de connexion internet', retryAfterSeconds: 0);
}

final class ScanGenericException extends ScanException {
  const ScanGenericException({required super.message})
    : super(retryAfterSeconds: 0);
}
