sealed class QuickAddException implements Exception {
  final String message;

  const QuickAddException({required this.message});
}

final class QuickAddNoAmountException extends QuickAddException {
  const QuickAddNoAmountException()
      : super(message: 'Aucun montant détecté dans la saisie');
}

final class QuickAddClassificationException extends QuickAddException {
  const QuickAddClassificationException({required super.message});
}
