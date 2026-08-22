import 'dart:async';
import 'dart:io';

import 'package:openai_dart/openai_dart.dart';

/// Ce qui peut rater sur un appel au fournisseur, ramené à ce dont l'app a
/// besoin pour décider : refuser la clé, réessayer, ou dégrader.
enum AiRequestFailure {
  invalidKey,
  permissionDenied,
  modelNotFound,
  quotaExceeded,
  serviceUnavailable,
  timeout,
  offline,
  malformedResponse,
  unknown;

  /// Une clé révoquée dégrade le moteur sans attendre le seuil d'échecs :
  /// réessayer ne peut pas la faire redevenir valide.
  bool get revokesKey =>
      this == invalidKey || this == permissionDenied || this == modelNotFound;

  static AiRequestFailure from(Object error) {
    return switch (error) {
      AiRequestException(:final failure) => failure,
      AuthenticationException() => invalidKey,
      PermissionDeniedException() => permissionDenied,
      NotFoundException() => modelNotFound,
      RateLimitException() => quotaExceeded,
      InternalServerException() => serviceUnavailable,
      RequestTimeoutException() || TimeoutException() => timeout,
      ConnectionException() || SocketException() => offline,
      ParseException() => malformedResponse,
      BadRequestException(:final code, :final message) =>
        _mentionsApiKey(code, message) ? invalidKey : unknown,
      ApiException(:final statusCode) => _fromStatusCode(statusCode),
      _ => unknown,
    };
  }

  static AiRequestFailure _fromStatusCode(int statusCode) {
    return switch (statusCode) {
      401 => invalidKey,
      403 => permissionDenied,
      404 => modelNotFound,
      429 => quotaExceeded,
      >= 500 => serviceUnavailable,
      _ => unknown,
    };
  }

  /// Gemini renvoie une clé invalide en 400 plutôt qu'en 401 : le code
  /// applicatif est la seule façon de distinguer ce cas d'une requête mal
  /// formée de notre côté.
  static bool _mentionsApiKey(String? code, String message) {
    final haystack = '${code ?? ''} $message'.toUpperCase();
    return haystack.contains('API_KEY') || haystack.contains('API KEY');
  }
}

/// L'échec tel que le reste de l'app le voit : aucune couche au-dessus du
/// client ne manipule les exceptions du SDK.
final class AiRequestException implements Exception {
  const AiRequestException(this.failure, {this.cause});

  final AiRequestFailure failure;
  final Object? cause;

  @override
  String toString() => 'AiRequestException(${failure.name}, cause: $cause)';
}
