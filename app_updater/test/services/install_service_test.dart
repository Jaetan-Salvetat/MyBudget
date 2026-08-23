import 'package:app_updater/app_updater.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_updater/src/services/install_service.dart';

void main() {
  group('InstallService', () {
    test('throws InstallException when file does not exist', () async {
      final service = InstallService();

      expect(
        () => service.installApk('/nonexistent/path/app.apk'),
        throwsA(isA<InstallException>().having(
          (e) => e.filePath,
          'filePath',
          '/nonexistent/path/app.apk',
        )),
      );
    });
  });
}
