import 'dart:io';

import 'package:app_updater/app_updater.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_updater/src/services/install_service.dart';

void main() {
  group('InstallService', () {
    late File apk;

    setUp(() async {
      apk = File(
        '${Directory.systemTemp.createTempSync('install_service').path}/app.apk',
      );
      await apk.writeAsString('apk');
    });

    test('throws InstallException when file does not exist', () {
      final service = InstallService();

      expect(
        () => service.installApk('/nonexistent/path/app.apk'),
        throwsA(
          isA<InstallException>().having(
            (e) => e.filePath,
            'filePath',
            '/nonexistent/path/app.apk',
          ),
        ),
      );
    });

    test('delegates the existing file to the installer', () async {
      String? received;
      final service = InstallService(
        installer: (filePath) async {
          received = filePath;
          return true;
        },
      );

      await service.installApk(apk.path);

      expect(received, apk.path);
    });

    test('throws InstallException when the installer reports a failure', () {
      final service = InstallService(installer: (_) async => false);

      expect(
        () => service.installApk(apk.path),
        throwsA(isA<InstallException>()),
      );
    });

    test('wraps installer errors into InstallException', () {
      final service = InstallService(
        installer: (_) async => throw StateError('boom'),
      );

      expect(
        () => service.installApk(apk.path),
        throwsA(
          isA<InstallException>().having(
            (e) => e.message,
            'message',
            contains('boom'),
          ),
        ),
      );
    });
  });
}
