import 'dart:io';

import 'package:app_installer/app_installer.dart';

import '../exceptions/update_exception.dart';

class InstallService {
  Future<void> installApk(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw InstallException(
        filePath: filePath,
        message: 'APK file not found',
      );
    }

    try {
      await AppInstaller.installApk(filePath);
    } catch (e) {
      throw InstallException(
        filePath: filePath,
        message: e.toString(),
      );
    }
  }
}
