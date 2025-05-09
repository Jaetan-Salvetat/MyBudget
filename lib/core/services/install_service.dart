import 'dart:io';
import 'package:app_installer/app_installer.dart';

class InstallService {
  Future<bool> installApk(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return false;
    }

    try {
      AppInstaller.installApk(filePath);
      return true;
    } catch (e) {
      return false;
    }
  }
}
