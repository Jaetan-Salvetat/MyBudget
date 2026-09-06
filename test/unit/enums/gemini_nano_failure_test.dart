import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/gemini_nano_failure.dart';

void main() {
  group('GeminiNanoFailure.fromCode', () {
    test('regroupe les appareils et AICore hors service', () {
      expect(
        GeminiNanoFailure.fromCode(GeminiNanoErrorCode.notAvailable),
        GeminiNanoFailure.unavailable,
      );
      expect(
        GeminiNanoFailure.fromCode(GeminiNanoErrorCode.aicoreIncompatible),
        GeminiNanoFailure.unavailable,
      );
      expect(
        GeminiNanoFailure.fromCode(GeminiNanoErrorCode.needsSystemUpdate),
        GeminiNanoFailure.unavailable,
      );
      expect(
        GeminiNanoFailure.fromCode(GeminiNanoErrorCode.notSupported),
        GeminiNanoFailure.unavailable,
      );
    });

    test('distingue les deux quotas AICore', () {
      expect(
        GeminiNanoFailure.fromCode(GeminiNanoErrorCode.busy),
        GeminiNanoFailure.quotaExceeded,
      );
      expect(
        GeminiNanoFailure.fromCode(GeminiNanoErrorCode.batteryQuotaExceeded),
        GeminiNanoFailure.quotaExceeded,
      );
    });

    test('isole le blocage en arrière-plan', () {
      expect(
        GeminiNanoFailure.fromCode(GeminiNanoErrorCode.backgroundUseBlocked),
        GeminiNanoFailure.backgroundBlocked,
      );
    });

    test('isole le manque de place', () {
      expect(
        GeminiNanoFailure.fromCode(GeminiNanoErrorCode.notEnoughDiskSpace),
        GeminiNanoFailure.outOfSpace,
      );
    });

    test('regroupe les refus de politique de contenu', () {
      expect(
        GeminiNanoFailure.fromCode(GeminiNanoErrorCode.requestProcessing),
        GeminiNanoFailure.policyRefused,
      );
      expect(
        GeminiNanoFailure.fromCode(GeminiNanoErrorCode.responseGeneration),
        GeminiNanoFailure.policyRefused,
      );
      expect(
        GeminiNanoFailure.fromCode(GeminiNanoErrorCode.responseProcessing),
        GeminiNanoFailure.policyRefused,
      );
    });

    test('regroupe les échecs de sortie structurée', () {
      expect(
        GeminiNanoFailure.fromCode(GeminiNanoErrorCode.structuredOutputRequest),
        GeminiNanoFailure.malformedResponse,
      );
      expect(
        GeminiNanoFailure.fromCode(
          GeminiNanoErrorCode.structuredOutputResponse,
        ),
        GeminiNanoFailure.malformedResponse,
      );
      expect(
        GeminiNanoFailure.fromCode(
          GeminiNanoErrorCode.structuredOutputMaxTokens,
        ),
        GeminiNanoFailure.malformedResponse,
      );
    });

    test('retombe sur unknown pour un code absent ou inconnu', () {
      expect(GeminiNanoFailure.fromCode(null), GeminiNanoFailure.unknown);
      expect(GeminiNanoFailure.fromCode(4242), GeminiNanoFailure.unknown);
    });
  });

  group('GeminiNanoFailure.fromPlatformCode', () {
    test('lit le code entier transmis par le canal', () {
      expect(
        GeminiNanoFailure.fromPlatformCode('${GeminiNanoErrorCode.busy}'),
        GeminiNanoFailure.quotaExceeded,
      );
    });

    test('retombe sur unknown quand le code n\'est pas un entier', () {
      expect(
        GeminiNanoFailure.fromPlatformCode('error'),
        GeminiNanoFailure.unknown,
      );
      expect(
        GeminiNanoFailure.fromPlatformCode(null),
        GeminiNanoFailure.unknown,
      );
    });
  });

  group('GeminiNanoFailure', () {
    test('porte un message affichable pour chaque cas', () {
      for (final failure in GeminiNanoFailure.values) {
        expect(failure.message, isNotEmpty);
      }
    });

    test('ne laisse que l\'appareil non éligible comme cas définitif', () {
      expect(GeminiNanoFailure.unavailable.isPermanent, isTrue);
      expect(GeminiNanoFailure.quotaExceeded.isPermanent, isFalse);
      expect(GeminiNanoFailure.unknown.isPermanent, isFalse);
    });
  });
}
