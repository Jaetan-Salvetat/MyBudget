import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mybudget/models/release_info_model.dart';

class GitHubService {
  final String _baseUrl =
      'https://api.github.com/repos/Jaetan-Salvetat/MyBudget';

  Future<ReleaseInfo?> getLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final assets = data['assets'] as List;
        if (assets.isEmpty) {
          return null;
        }

        final apkAsset = assets.firstWhere(
          (asset) => asset['name'].toString().endsWith('.apk'),
          orElse: () => null,
        );

        if (apkAsset == null) {
          return null;
        }

        return ReleaseInfo(
          version: data['tag_name'].toString().replaceAll('v', ''),
          title: data['name'] as String,
          notes: data['body'] as String,
          downloadUrl: apkAsset['browser_download_url'] as String,
          publishedAt: DateTime.parse(data['published_at'] as String),
          assetSize: apkAsset['size'] as int,
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
