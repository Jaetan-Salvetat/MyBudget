import 'dart:async';
import 'dart:io';

import 'package:openai_dart/openai_dart.dart';

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

  static bool _mentionsApiKey(String? code, String message) {
    final haystack = '${code ?? ''} $message'.toUpperCase();
    return haystack.contains('API_KEY') || haystack.contains('API KEY');
  }
}

final class AiRequestException implements Exception {
  const AiRequestException(this.failure, {this.cause});

  final AiRequestFailure failure;
  final Object? cause;

  @override
  String toString() => 'AiRequestException(${failure.name}, cause: $cause)';
}
