import 'dart:io';

import 'package:flutter_app_installer/flutter_app_installer.dart';

import '../exceptions/update_exception.dart';

typedef ApkInstaller = Future<bool> Function(String filePath);

class InstallService {
  InstallService({ApkInstaller? installer})
      : _installer = installer ?? _installWithPlugin;

  final ApkInstaller _installer;

  static Future<bool> _installWithPlugin(String filePath) {
    return FlutterAppInstaller().installApk(filePath: filePath);
  }

  Future<void> installApk(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw InstallException(
        filePath: filePath,
        message: 'APK file not found',
      );
    }

    final bool installed;
    try {
      installed = await _installer(filePath);
    } catch (e) {
      throw InstallException(
        filePath: filePath,
        message: e.toString(),
      );
    }

    if (!installed) {
      throw InstallException(
        filePath: filePath,
        message: 'The system installer rejected the APK',
      );
    }
  }
}
