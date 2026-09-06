import 'package:flutter_test/flutter_test.dart';

import '../../../tool/release/store_version.dart';

void main() {
  group('StoreVersion.parse', () {
    test('lit une version de pubspec avec numero de build', () {
      expect(StoreVersion.parse('1.0.0+35'), const StoreVersion(1, 0, 0));
    });

    test('lit une version sans numero de build', () {
      expect(StoreVersion.parse('2.13.4'), const StoreVersion(2, 13, 4));
    });

    test('refuse une version incomplete', () {
      expect(
        () => StoreVersion.parse('1.0'),
        throwsA(isA<StoreVersionException>()),
      );
    });

    test('refuse une version non numerique', () {
      expect(
        () => StoreVersion.parse('1.0.x'),
        throwsA(isA<StoreVersionException>()),
      );
    });
  });

  group('StoreVersion.code', () {
    test('encode chaque champ dans sa propre tranche', () {
      expect(const StoreVersion(1, 0, 0).code, 1000000);
      expect(const StoreVersion(1, 2, 3).code, 1020003);
      expect(const StoreVersion(2, 99, 9999).code, 2999999);
    });

    test('conserve l ordre semver au dela du neuvieme patch', () {
      expect(
        const StoreVersion(1, 0, 10).code,
        lessThan(const StoreVersion(1, 1, 0).code),
      );
    });

    test('reste sous le plafond impose par Play', () {
      expect(
        const StoreVersion(2100, 0, 0).code,
        lessThanOrEqualTo(maxVersionCode),
      );
    });
  });

  group('StoreVersion.fromCode', () {
    test('decode un code en version', () {
      expect(StoreVersion.fromCode(1020003), const StoreVersion(1, 2, 3));
    });

    test('est l inverse de code', () {
      const StoreVersion version = StoreVersion(3, 7, 128);

      expect(StoreVersion.fromCode(version.code), version);
    });
  });

  group('nextStoreVersion', () {
    test('demarre le patch a zero quand rien n est publie', () {
      expect(
        nextStoreVersion(major: 1, minor: 0, highestPublishedCode: null),
        const StoreVersion(1, 0, 0),
      );
    });

    test('incremente le patch quand la mineure est inchangee', () {
      expect(
        nextStoreVersion(
          major: 1,
          minor: 0,
          highestPublishedCode: const StoreVersion(1, 0, 6).code,
        ),
        const StoreVersion(1, 0, 7),
      );
    });

    test('remet le patch a zero quand la mineure avance', () {
      expect(
        nextStoreVersion(
          major: 1,
          minor: 1,
          highestPublishedCode: const StoreVersion(1, 0, 42).code,
        ),
        const StoreVersion(1, 1, 0),
      );
    });

    test('remet le patch a zero quand la majeure avance', () {
      expect(
        nextStoreVersion(
          major: 2,
          minor: 0,
          highestPublishedCode: const StoreVersion(1, 9, 3).code,
        ),
        const StoreVersion(2, 0, 0),
      );
    });

    test('refuse une version anterieure a celle deja publiee', () {
      expect(
        () => nextStoreVersion(
          major: 1,
          minor: 0,
          highestPublishedCode: const StoreVersion(1, 2, 0).code,
        ),
        throwsA(isA<StoreVersionException>()),
      );
    });

    test('refuse un patch qui deborde de sa tranche', () {
      expect(
        () => nextStoreVersion(
          major: 1,
          minor: 0,
          highestPublishedCode: const StoreVersion(1, 0, maxPatch).code,
        ),
        throwsA(isA<StoreVersionException>()),
      );
    });

    test('refuse une mineure qui deborde de sa tranche', () {
      expect(
        () => nextStoreVersion(
          major: 1,
          minor: maxMinor + 1,
          highestPublishedCode: null,
        ),
        throwsA(isA<StoreVersionException>()),
      );
    });

    test('refuse une majeure au dela du plafond Play', () {
      expect(
        () =>
            nextStoreVersion(major: 2101, minor: 0, highestPublishedCode: null),
        throwsA(isA<StoreVersionException>()),
      );
    });
  });
}
