import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final String gradle = File('android/app/build.gradle.kts').readAsStringSync();

  group('build.gradle.kts', () {
    test('déclare la saveur store dans la dimension env', () {
      expect(
        gradle,
        contains(
          RegExp(
            r'create\("store"\)\s*\{\s*dimension\s*=\s*"env"',
            multiLine: true,
          ),
        ),
      );
    });

    test('la saveur store garde l\'identifiant d\'application nu', () {
      final RegExpMatch? block = RegExp(
        r'create\("store"\)\s*\{(.*?)\n        \}',
        dotAll: true,
      ).firstMatch(gradle);

      expect(block, isNotNull);
      expect(block!.group(1), isNot(contains('applicationIdSuffix')));
    });
  });

  group('AndroidManifest de la saveur store', () {
    final File manifest = File('android/app/src/store/AndroidManifest.xml');

    test('existe', () {
      expect(manifest.existsSync(), isTrue);
    });

    test('retire les permissions que Play n\'accepte pas', () {
      const List<String> removed = <String>[
        'REQUEST_INSTALL_PACKAGES',
        'MANAGE_EXTERNAL_STORAGE',
        'READ_EXTERNAL_STORAGE',
        'WRITE_EXTERNAL_STORAGE',
      ];
      final String source = manifest.readAsStringSync();

      for (final String permission in removed) {
        expect(
          source,
          contains(
            RegExp(
              'android:name="android\\.permission\\.$permission"'
              r'\s+tools:node="remove"',
            ),
          ),
          reason: permission,
        );
      }
    });
  });
}
