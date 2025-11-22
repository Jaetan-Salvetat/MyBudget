class ReleaseInfo {
  final String version;
  final String title;
  final String notes;
  final String downloadUrl;
  final DateTime publishedAt;
  final int assetSize;

  ReleaseInfo({
    required this.version,
    required this.title,
    required this.notes,
    required this.downloadUrl,
    required this.publishedAt,
    required this.assetSize,
  });
}
