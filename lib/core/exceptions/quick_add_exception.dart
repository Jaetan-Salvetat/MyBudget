sealed class QuickAddException implements Exception {
  const QuickAddException({required this.message});
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class QuickAddNoAmountException extends QuickAddException {
  const QuickAddNoAmountException()
    : super(message: 'Aucun montant détecté dans la saisie');
}

final class QuickAddClassificationException extends QuickAddException {
  const QuickAddClassificationException({required super.message});
}

final class QuickAddEngineUnavailableException extends QuickAddException {
  const QuickAddEngineUnavailableException({required super.message});
}
