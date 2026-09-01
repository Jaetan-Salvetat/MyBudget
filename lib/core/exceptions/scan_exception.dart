sealed class ScanException implements Exception {
  final String message;

  const ScanException({required this.message});
}

final class ScanUnreadableException extends ScanException {
  const ScanUnreadableException()
    : super(message: 'Aucun texte lisible sur cette photo');
}

final class ScanNoItemsException extends ScanException {
  const ScanNoItemsException()
    : super(message: 'Aucun article n\'a pu être lu sur ce ticket');
}

final class ScanGenericException extends ScanException {
  const ScanGenericException({required super.message});
}

final class ScanUnavailableException extends ScanException {
  const ScanUnavailableException()
    : super(message: 'La lecture de tickets n\'est pas disponible');
}
