class ReleaseAsset {
  final String name;
  final String downloadUrl;
  final int size;
  final String contentType;

  const ReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
    required this.contentType,
  });

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: json['name'] as String,
      downloadUrl: json['browser_download_url'] as String,
      size: json['size'] as int,
      contentType: json['content_type'] as String,
    );
  }
}

class ReleaseInfo {
  final String version;
  final String tagName;
  final String title;
  final String notes;
  final DateTime publishedAt;
  final bool isPrerelease;
  final List<ReleaseAsset> assets;

  const ReleaseInfo({
    required this.version,
    required this.tagName,
    required this.title,
    required this.notes,
    required this.publishedAt,
    required this.isPrerelease,
    required this.assets,
  });

  ReleaseAsset? get defaultApkAsset {
    for (final asset in assets) {
      if (asset.name.endsWith('.apk')) return asset;
    }
    return null;
  }

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    final assets = (json['assets'] as List<dynamic>)
        .map((a) => ReleaseAsset.fromJson(a as Map<String, dynamic>))
        .toList();

    final tagName = json['tag_name'] as String;
    final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;

    return ReleaseInfo(
      version: version,
      tagName: tagName,
      title: (json['name'] as String?) ?? '',
      notes: (json['body'] as String?) ?? '',
      publishedAt: DateTime.parse(json['published_at'] as String),
      isPrerelease: json['prerelease'] as bool,
      assets: assets,
    );
  }
}
