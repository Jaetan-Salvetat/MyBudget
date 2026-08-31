enum GeminiNanoStatus {
  available(id: 'available'),
  downloadable(id: 'downloadable'),
  downloading(id: 'downloading'),
  unavailable(id: 'unavailable');

  const GeminiNanoStatus({required this.id});

  final String id;

  static const GeminiNanoStatus fallback = unavailable;

  bool get isReady => this == available;

  bool get isDownloadable => this == downloadable;

  bool get isSelectable => this != unavailable;

  static GeminiNanoStatus fromId(String? id) {
    for (final status in values) {
      if (status.id == id) return status;
    }
    return fallback;
  }
}
