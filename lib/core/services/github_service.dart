import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mybudget/models/release_info_model.dart';

class GitHubService {
  final String _baseUrl =
      'https://api.github.com/repos/Jaetan-Salvetat/MyBudget';
  final http.Client _client;

  GitHubService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<ReleaseInfo>> getReleases() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/releases'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((json) => _parseRelease(json))
            .where((release) => release != null)
            .cast<ReleaseInfo>()
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  ReleaseInfo? _parseRelease(Map<String, dynamic> data) {
    try {
      final assets = data['assets'] as List;
      if (assets.isEmpty) return null;

      final apkAsset = assets.firstWhere(
        (asset) => asset['name'].toString().endsWith('.apk'),
        orElse: () => null,
      );

      if (apkAsset == null) return null;

      final rawTag = data['tag_name'].toString();
      final version = rawTag.replaceAll('v', '').replaceAll('-beta', '');

      return ReleaseInfo(
        version: version,
        title: data['name'] as String,
        notes: data['body'] as String,
        downloadUrl: apkAsset['browser_download_url'] as String,
        publishedAt: DateTime.parse(data['published_at'] as String),
        assetSize: apkAsset['size'] as int,
        isPrerelease: data['prerelease'] as bool? ?? false,
      );
    } catch (e) {
      return null;
    }
  }

  Future<ReleaseInfo?> getLatestRelease() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseRelease(data);
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
