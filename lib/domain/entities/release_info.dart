import 'package:equatable/equatable.dart';

class ReleaseInfo extends Equatable {
  final String version;
  final String title;
  final String notes;
  final String downloadUrl;
  final DateTime publishedAt;
  final int assetSize;

  const ReleaseInfo({
    required this.version,
    required this.title,
    required this.notes,
    required this.downloadUrl,
    required this.publishedAt,
    required this.assetSize,
  });

  @override
  List<Object?> get props => [version, title, notes, downloadUrl, publishedAt, assetSize];
}

enum UpdateStatus {
  checking,
  upToDate,
  available,
  downloading,
  readyToInstall,
  installing,
  error,
}
