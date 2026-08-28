/// Ce qui peut empêcher un scan d'aboutir. Le ticket est lu sur l'appareil :
/// aucune de ces erreurs ne dépend du réseau, d'une clé ou d'un quota.
sealed class ScanException implements Exception {
  final String message;

  const ScanException({required this.message});
}

/// Aucun texte exploitable sur la photo : cadrage, flou, ou ce n'est pas un
/// ticket. Reprendre la photo est la seule issue.
final class ScanUnreadableException extends ScanException {
  const ScanUnreadableException()
    : super(message: 'Aucun texte lisible sur cette photo');
}

/// Du texte a été lu, mais aucune ligne d'article n'en ressort.
final class ScanNoItemsException extends ScanException {
  const ScanNoItemsException()
    : super(message: 'Aucun article n\'a pu être lu sur ce ticket');
}

/// Le pipeline ou le modèle embarqué a échoué : rien que l'utilisateur puisse
/// corriger en reprenant la photo, le message reste donc générique.
final class ScanGenericException extends ScanException {
  const ScanGenericException({required super.message});
}
