import 'package:app_updater/app_updater.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_updater/src/services/version_service.dart';

void main() {
  group('VersionService - default semver', () {
    final service = VersionService();

    test('detects newer version', () {
      expect(service.isNewer('1.0.0', '1.0.1'), true);
      expect(service.isNewer('1.0.0', '1.1.0'), true);
      expect(service.isNewer('1.0.0', '2.0.0'), true);
    });

    test('detects same version', () {
      expect(service.isNewer('1.0.0', '1.0.0'), false);
    });

    test('detects older version', () {
      expect(service.isNewer('2.0.0', '1.0.0'), false);
      expect(service.isNewer('1.1.0', '1.0.0'), false);
      expect(service.isNewer('1.0.1', '1.0.0'), false);
    });

    test('handles v prefix', () {
      expect(service.isNewer('v1.0.0', '1.0.1'), true);
      expect(service.isNewer('1.0.0', 'v1.0.1'), true);
      expect(service.isNewer('v1.0.0', 'v1.0.1'), true);
    });

    test('handles two-part versions', () {
      expect(service.isNewer('1.0', '1.1'), true);
      expect(service.isNewer('1.1', '1.0'), false);
    });

    test('handles prerelease suffix by stripping it', () {
      expect(service.isNewer('1.0.0', '1.0.1-beta.1'), true);
      expect(service.isNewer('1.0.1-beta.1', '1.0.1'), false);
    });

    test('throws VersionParseException on malformed version', () {
      expect(
        () => service.isNewer('not_a_version', '1.0.0'),
        throwsA(isA<VersionParseException>()),
      );
      expect(
        () => service.isNewer('1.0.0', 'abc'),
        throwsA(isA<VersionParseException>()),
      );
    });

    test('throws on single-part version', () {
      expect(
        () => service.isNewer('1', '2'),
        throwsA(isA<VersionParseException>()),
      );
    });
  });

  group('VersionService - custom comparator', () {
    test('delegates to custom comparator', () {
      final service = VersionService(
        comparator: (current, candidate) => candidate == 'newer',
      );

      expect(service.isNewer('1.0.0', 'newer'), true);
      expect(service.isNewer('1.0.0', 'older'), false);
    });

    test('custom comparator bypasses semver parsing', () {
      final service = VersionService(
        comparator: (current, candidate) => true,
      );

      expect(service.isNewer('not_a_version', 'also_not_a_version'), true);
    });
  });
}
