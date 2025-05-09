import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';
import 'package:mybudget/domain/entities/release_info.dart';
import 'package:mybudget/core/services/github_service.dart';
import 'package:mybudget/core/services/download_service.dart';
import 'package:mybudget/core/services/install_service.dart';
import 'package:mybudget/presentation/screens/update_screen.dart';

class UpdateController extends GetxController {
  final GitHubService _gitHubService = GitHubService();
  final DownloadService _downloadService = DownloadService();
  final InstallService _installService = InstallService();

  final Rx<UpdateStatus> status = UpdateStatus.checking.obs;
  final Rx<ReleaseInfo?> latestRelease = Rxn<ReleaseInfo>();
  final RxDouble downloadProgress = 0.0.obs;
  final RxString downloadedFilePath = ''.obs;

  Future<bool> checkForUpdates() async {
    status.value = UpdateStatus.checking;

    try {
      final releaseInfo = await _gitHubService.getLatestRelease();
      if (releaseInfo == null) {
        status.value = UpdateStatus.upToDate;
        return false;
      }

      latestRelease.value = releaseInfo;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);
      final remoteVersion = Version.parse(releaseInfo.version);

      if (remoteVersion > currentVersion) {
        status.value = UpdateStatus.available;
        Get.to(() => const UpdateScreen());
        return true;
      } else {
        status.value = UpdateStatus.upToDate;
        return false;
      }
    } catch (e) {
      status.value = UpdateStatus.error;
      return false;
    }
  }

  Future<bool> downloadUpdate() async {
    if (latestRelease.value == null) return false;

    status.value = UpdateStatus.downloading;
    downloadProgress.value = 0.0;

    final fileName = 'mybudget-${latestRelease.value!.version}.apk';
    final filePath = await _downloadService.downloadApk(
      latestRelease.value!.downloadUrl,
      fileName,
      (progress) => downloadProgress.value = progress,
    );

    if (filePath == null) {
      status.value = UpdateStatus.error;
      return false;
    }

    downloadedFilePath.value = filePath;
    status.value = UpdateStatus.readyToInstall;
    return true;
  }

  Future<bool> installUpdate() async {
    if (downloadedFilePath.value.isEmpty) return false;

    status.value = UpdateStatus.installing;

    final success = await _installService.installApk(downloadedFilePath.value);

    if (!success) {
      status.value = UpdateStatus.error;
      return false;
    }

    return true;
  }
}
