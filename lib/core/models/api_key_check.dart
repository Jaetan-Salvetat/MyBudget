import 'package:mybudget/core/enums/ai_provider.dart';

enum ApiKeyDenialReason {
  invalidFormat,
  foreignProvider,
  invalidKey,
  permissionDenied,
  modelNotFound,
  serviceUnavailable,
  timeout,
  offline,
  unknown;

  String messageFor(AiProvider provider, {String? foreignVendor}) {
    return switch (this) {
      invalidFormat => provider.keyFormatHint,
      foreignProvider =>
        'Cette clé vient de ${foreignVendor ?? 'un autre service'}. '
            'Choisissez ${provider.label} ou collez une clé ${provider.label}.',
      invalidKey => 'Clé non reconnue. Vérifiez qu\'elle est copiée en entier.',
      permissionDenied =>
        'Cette clé existe mais n\'a pas accès à l\'API. '
            'Activez-la dans ${provider.consoleLabel}.',
      modelNotFound =>
        'Le modèle attendu n\'est plus disponible. Mettez l\'application à jour.',
      serviceUnavailable =>
        'Le service ne répond pas. Réessayez dans un instant.',
      timeout => 'La vérification a été trop longue. Réessayez.',
      offline => 'Pas de connexion internet. Impossible de vérifier la clé.',
      unknown => 'La vérification a échoué. Réessayez.',
    };
  }
}

sealed class ApiKeyCheck {
  const ApiKeyCheck();
}

final class ApiKeyAccepted extends ApiKeyCheck {
  const ApiKeyAccepted({this.quotaExhausted = false});

  final bool quotaExhausted;
}

final class ApiKeyDenied extends ApiKeyCheck {
  const ApiKeyDenied({required this.reason, required this.message});

  final ApiKeyDenialReason reason;
  final String message;
}
