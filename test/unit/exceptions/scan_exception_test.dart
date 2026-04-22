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

  group('ScanGenericException', () {
    test('carries details and has zero retryAfterSeconds', () {
      const exception = ScanGenericException(details: 'timeout');
      expect(exception.details, 'timeout');
      expect(exception.retryAfterSeconds, 0);
    });

    test('has correct message', () {
      const exception = ScanGenericException(details: 'network error');
      expect(exception.message, 'Impossible d\'analyser le ticket');
    });
  });

  group('exhaustive switch', () {
    test('covers all subtypes', () {
      final List<ScanException> exceptions = [
        const ScanCooldownException(retryAfterSeconds: 10),
        const ScanRateLimitException(),
        const ScanGenericException(details: 'test'),
      ];

      for (final exception in exceptions) {
        final result = switch (exception) {
          ScanCooldownException() => 'cooldown',
          ScanRateLimitException() => 'rate_limit',
          ScanGenericException() => 'generic',
        };
        expect(result, isNotEmpty);
      }
    });
  });
}
