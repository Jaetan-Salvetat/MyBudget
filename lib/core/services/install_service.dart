import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class InstallService {
  Future<bool> installApk(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return false;
    }
    
    try {
      if (await Permission.requestInstallPackages.request().isGranted) {
        final uri = Uri.file(filePath);
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
