abstract final class GeminiNanoErrorCode {
  static const int requestProcessing = 4;
  static const int cancelled = 7;
  static const int notAvailable = 8;
  static const int busy = 9;
  static const int responseProcessing = 11;
  static const int requestTooLarge = 12;
  static const int responseGeneration = 15;
  static const int notSupported = 16;
  static const int batteryQuotaExceeded = 27;
  static const int backgroundUseBlocked = 30;
  static const int notEnoughDiskSpace = 501;
  static const int needsSystemUpdate = 604;
  static const int aicoreIncompatible = -101;
  static const int structuredOutputRequest = -104;
  static const int structuredOutputResponse = -105;
  static const int structuredOutputMaxTokens = -106;
}

enum GeminiNanoFailure {
  unavailable(
    message: 'Gemini Nano n\'est pas disponible sur cet appareil.',
    isPermanent: true,
  ),
  notInstalled(message: 'Le modèle Gemini Nano n\'est pas encore installé.'),
  outOfSpace(message: 'Pas assez d\'espace libre pour installer Gemini Nano.'),
  quotaExceeded(
    message: 'Gemini Nano a atteint son quota. Réessaie dans un moment.',
  ),
  backgroundBlocked(
    message: 'Gemini Nano ne répond que si l\'app est à l\'écran.',
  ),
  cancelled(message: 'Analyse interrompue.'),
  inputTooLong(message: 'Saisie trop longue pour Gemini Nano.'),
  policyRefused(message: 'Gemini Nano a refusé d\'analyser cette saisie.'),
  malformedResponse(
    message: 'Gemini Nano n\'a pas rendu de réponse exploitable.',
  ),
  unknown(message: 'Gemini Nano n\'a pas répondu.');

  const GeminiNanoFailure({required this.message, this.isPermanent = false});

  final String message;
  final bool isPermanent;

  static GeminiNanoFailure fromCode(int? code) {
    return switch (code) {
      GeminiNanoErrorCode.notAvailable ||
      GeminiNanoErrorCode.notSupported ||
      GeminiNanoErrorCode.aicoreIncompatible ||
      GeminiNanoErrorCode.needsSystemUpdate => unavailable,
      GeminiNanoErrorCode.notEnoughDiskSpace => outOfSpace,
      GeminiNanoErrorCode.busy ||
      GeminiNanoErrorCode.batteryQuotaExceeded => quotaExceeded,
      GeminiNanoErrorCode.backgroundUseBlocked => backgroundBlocked,
      GeminiNanoErrorCode.cancelled => cancelled,
      GeminiNanoErrorCode.requestTooLarge => inputTooLong,
      GeminiNanoErrorCode.requestProcessing ||
      GeminiNanoErrorCode.responseGeneration ||
      GeminiNanoErrorCode.responseProcessing => policyRefused,
      GeminiNanoErrorCode.structuredOutputRequest ||
      GeminiNanoErrorCode.structuredOutputResponse ||
      GeminiNanoErrorCode.structuredOutputMaxTokens => malformedResponse,
      _ => unknown,
    };
  }

  static GeminiNanoFailure fromPlatformCode(String? code) =>
      fromCode(code == null ? null : int.tryParse(code));
}

final class GeminiNanoException implements Exception {
  const GeminiNanoException(this.failure, {this.cause});

  final GeminiNanoFailure failure;
  final Object? cause;

  String get message => failure.message;

  @override
  String toString() => 'GeminiNanoException(${failure.name}, cause: $cause)';
}
