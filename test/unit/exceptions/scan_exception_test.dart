import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';

void main() {
  group('ScanException', () {
    test('scanCooldownSeconds is 120', () {
      expect(ScanException.scanCooldownSeconds, 120);
    });
  });

  group('ScanCooldownException', () {
    test('carries retryAfterSeconds', () {
      const exception = ScanCooldownException(retryAfterSeconds: 45);
      expect(exception.retryAfterSeconds, 45);
      expect(exception.message, 'Veuillez patienter avant de relancer un scan');
    });

    test('implements ScanException', () {
      const exception = ScanCooldownException(retryAfterSeconds: 10);
      expect(exception, isA<ScanException>());
    });
  });

  group('ScanRateLimitException', () {
    test('uses scanCooldownSeconds as retryAfterSeconds', () {
      const exception = ScanRateLimitException();
      expect(exception.retryAfterSeconds, ScanException.scanCooldownSeconds);
    });

    test('has correct message', () {
      const exception = ScanRateLimitException();
      expect(
        exception.message,
        'Le service d\'analyse est temporairement surchargé',
      );
    });
  });

  group('ScanServiceUnavailableException', () {
    test('uses scanCooldownSeconds as retryAfterSeconds', () {
      const exception = ScanServiceUnavailableException();
      expect(exception.retryAfterSeconds, ScanException.scanCooldownSeconds);
    });

    test('has correct message', () {
      const exception = ScanServiceUnavailableException();
      expect(
        exception.message,
        'Le service d\'analyse est momentanément indisponible',
      );
    });
  });

  group('ScanGenericException', () {
    test('has zero retryAfterSeconds', () {
      const exception = ScanGenericException(message: 'erreur');
      expect(exception.retryAfterSeconds, 0);
    });

    test('carries custom message', () {
      const exception = ScanGenericException(message: 'message custom');
      expect(exception.message, 'message custom');
    });
  });

  group('fromFailure', () {
    test('a revoked key asks for a new one instead of a retry', () {
      final result = ScanException.fromFailure(AiRequestFailure.invalidKey);
      expect(result, isA<ScanInvalidApiKeyException>());
      expect(result.retryAfterSeconds, 0);
    });

    test('a denied permission is a key problem too', () {
      expect(
        ScanException.fromFailure(AiRequestFailure.permissionDenied),
        isA<ScanInvalidApiKeyException>(),
      );
    });

    test('an unknown model is a key problem too', () {
      expect(
        ScanException.fromFailure(AiRequestFailure.modelNotFound),
        isA<ScanInvalidApiKeyException>(),
      );
    });

    test('an exhausted quota waits for the cooldown', () {
      final result = ScanException.fromFailure(AiRequestFailure.quotaExceeded);
      expect(result, isA<ScanRateLimitException>());
      expect(result.retryAfterSeconds, ScanException.scanCooldownSeconds);
    });

    test('an unavailable service waits for the cooldown', () {
      expect(
        ScanException.fromFailure(AiRequestFailure.serviceUnavailable),
        isA<ScanServiceUnavailableException>(),
      );
    });

    test('a lost connection is retryable right away', () {
      final result = ScanException.fromFailure(AiRequestFailure.offline);
      expect(result, isA<ScanOfflineException>());
      expect(result.retryAfterSeconds, 0);
    });

    test('a timeout is retryable right away', () {
      final result = ScanException.fromFailure(AiRequestFailure.timeout);
      expect(result, isA<ScanGenericException>());
      expect(result.retryAfterSeconds, 0);
    });

    test('a malformed answer never surfaces the parsing detail', () {
      expect(
        ScanException.fromFailure(AiRequestFailure.malformedResponse),
        isA<ScanGenericException>(),
      );
    });

    test('an unknown failure falls back to the generic message', () {
      final result = ScanException.fromFailure(AiRequestFailure.unknown);
      expect(result.message, 'Impossible d\'analyser le ticket');
    });

    test('covers every failure the client can report', () {
      for (final failure in AiRequestFailure.values) {
        expect(ScanException.fromFailure(failure), isA<ScanException>());
      }
    });
  });

  group('exhaustive switch', () {
    test('covers all subtypes', () {
      final List<ScanException> exceptions = [
        const ScanCooldownException(retryAfterSeconds: 10),
        const ScanRateLimitException(),
        const ScanServiceUnavailableException(),
        const ScanMissingApiKeyException(),
        const ScanInvalidApiKeyException(),
        const ScanOfflineException(),
        const ScanGenericException(message: 'test'),
      ];

      for (final exception in exceptions) {
        final result = switch (exception) {
          ScanCooldownException() => 'cooldown',
          ScanRateLimitException() => 'rate_limit',
          ScanServiceUnavailableException() => 'unavailable',
          ScanMissingApiKeyException() => 'missing_api_key',
          ScanInvalidApiKeyException() => 'invalid_api_key',
          ScanOfflineException() => 'offline',
          ScanGenericException() => 'generic',
        };
        expect(result, isNotEmpty);
      }
    });
  });
}
