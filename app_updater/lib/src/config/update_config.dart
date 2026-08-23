import 'package:http/http.dart' as http;

import '../models/release_info.dart';

typedef VersionComparator = bool Function(
  String currentVersion,
  String candidateVersion,
);

typedef AssetSelector = ReleaseAsset? Function(List<ReleaseAsset> assets);

enum UpdateChannel { stable, beta }

class UpdateConfig {
  final String githubOwner;
  final String githubRepo;
  final String? currentVersion;
  final String? githubToken;
  final UpdateChannel channel;
  final VersionComparator? versionComparator;
  final AssetSelector? assetSelector;
  final int maxRetries;
  final Duration retryDelay;
  final http.Client? httpClient;

  const UpdateConfig({
    required this.githubOwner,
    required this.githubRepo,
    this.currentVersion,
    this.githubToken,
    this.channel = UpdateChannel.stable,
    this.versionComparator,
    this.assetSelector,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.httpClient,
  });
}
