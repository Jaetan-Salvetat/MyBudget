import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/update_config.dart';
import '../exceptions/update_exception.dart';
import '../models/release_info.dart';

class GitHubService {
  final String _owner;
  final String _repo;
  final String? _token;
  final http.Client _client;

  GitHubService({
    required String owner,
    required String repo,
    String? token,
    http.Client? client,
  })  : _owner = owner,
        _repo = repo,
        _token = token,
        _client = client ?? http.Client();

  Future<List<ReleaseInfo>> getReleases() async {
    final uri = Uri.https(
      'api.github.com',
      '/repos/$_owner/$_repo/releases',
    );

    final http.Response response;
    try {
      response = await _client.get(uri, headers: _headers);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    }

    if (response.statusCode != 200) {
      throw GitHubApiException(
        statusCode: response.statusCode,
        message: 'Failed to fetch releases: ${response.reasonPhrase}',
      );
    }

    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    final releases = <ReleaseInfo>[];

    for (final item in json) {
      try {
        releases.add(ReleaseInfo.fromJson(item as Map<String, dynamic>));
      } catch (_) {
        continue;
      }
    }

    return releases;
  }

  List<ReleaseInfo> filterByChannel(
    List<ReleaseInfo> releases,
    UpdateChannel channel,
  ) {
    return switch (channel) {
      UpdateChannel.stable =>
        releases.where((r) => !r.isPrerelease).toList(),
      UpdateChannel.beta =>
        releases.where((r) => r.isPrerelease).toList(),
    };
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
    };
    if (_token != null) {
      headers['Authorization'] = 'token $_token';
    }
    return headers;
  }
}
