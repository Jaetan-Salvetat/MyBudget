enum LocalModelStatus {
  none,
  downloading,
  ready;

  String get label {
    switch (this) {
      case LocalModelStatus.none:
        return 'Non installée';
      case LocalModelStatus.downloading:
        return 'Téléchargement…';
      case LocalModelStatus.ready:
        return 'Prête';
    }
  }

  static LocalModelStatus fromString(String value) {
    return LocalModelStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LocalModelStatus.none,
    );
  }
}
