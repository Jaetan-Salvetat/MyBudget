import 'package:flutter_test/flutter_test.dart';
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

  group('fromServerMessage', () {
    test('429 returns ScanRateLimitException', () {
      final result = ScanException.fromServerMessage('429 RESOURCE_EXHAUSTED');
      expect(result, isA<ScanRateLimitException>());
    });

    test('RESOURCE_EXHAUSTED returns ScanRateLimitException', () {
      final result = ScanException.fromServerMessage(
        'You\'ve exceeded the rate limit',
      );
      expect(result, isA<ScanGenericException>());

      final result2 = ScanException.fromServerMessage('RESOURCE_EXHAUSTED');
      expect(result2, isA<ScanRateLimitException>());
    });

    test('503 returns ScanServiceUnavailableException', () {
      final result = ScanException.fromServerMessage('503 UNAVAILABLE');
      expect(result, isA<ScanServiceUnavailableException>());
    });

    test('UNAVAILABLE returns ScanServiceUnavailableException', () {
      final result = ScanException.fromServerMessage(
        'The service may be temporarily unavailable',
      );
      expect(result, isA<ScanServiceUnavailableException>());
    });

    test('500 returns ScanGenericException with server error message', () {
      final result = ScanException.fromServerMessage('500 INTERNAL');
      expect(result, isA<ScanGenericException>());
      expect(result.message, 'Une erreur interne est survenue côté serveur');
    });

    test('504 returns ScanGenericException with timeout message', () {
      final result = ScanException.fromServerMessage('DEADLINE_EXCEEDED');
      expect(result, isA<ScanGenericException>());
      expect(
        result.message,
        'L\'analyse a pris trop de temps, veuillez réessayer',
      );
    });

    test('403 returns ScanGenericException with permission message', () {
      final result = ScanException.fromServerMessage('PERMISSION_DENIED');
      expect(result, isA<ScanGenericException>());
      expect(result.message, 'Accès refusé au service d\'analyse');
    });

    test('404 returns ScanGenericException with unavailable message', () {
      final result = ScanException.fromServerMessage('NOT_FOUND');
      expect(result, isA<ScanGenericException>());
      expect(result.message, 'Le service d\'analyse est indisponible');
    });

    test('400 returns ScanGenericException with image error message', () {
      final result = ScanException.fromServerMessage('INVALID_ARGUMENT');
      expect(result, isA<ScanGenericException>());
      expect(result.message, 'L\'image envoyée n\'a pas pu être traitée');
    });

    test('unknown error returns generic fallback', () {
      final result = ScanException.fromServerMessage('something unexpected');
      expect(result, isA<ScanGenericException>());
      expect(result.message, 'Impossible d\'analyser le ticket');
    });
  });

  group('exhaustive switch', () {
    test('covers all subtypes', () {
      final List<ScanException> exceptions = [
        const ScanCooldownException(retryAfterSeconds: 10),
        const ScanRateLimitException(),
        const ScanServiceUnavailableException(),
        const ScanGenericException(message: 'test'),
      ];

      for (final exception in exceptions) {
        final result = switch (exception) {
          ScanCooldownException() => 'cooldown',
          ScanRateLimitException() => 'rate_limit',
          ScanServiceUnavailableException() => 'unavailable',
          ScanGenericException() => 'generic',
        };
        expect(result, isNotEmpty);
      }
    });
  });
}
