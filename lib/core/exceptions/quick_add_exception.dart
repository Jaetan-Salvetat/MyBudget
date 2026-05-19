sealed class QuickAddException implements Exception {
  final String message;

  const QuickAddException({required this.message});
}

final class QuickAddNetworkException extends QuickAddException {
  const QuickAddNetworkException()
      : super(message: 'Pas de connexion internet');
}

final class QuickAddApiException extends QuickAddException {
  const QuickAddApiException({required super.message});
}

final class QuickAddParseException extends QuickAddException {
  const QuickAddParseException()
      : super(message: 'Impossible d\'analyser la dépense');
}

final class QuickAddRateLimitException extends QuickAddException {
  final int remaining;

  const QuickAddRateLimitException({required this.remaining})
      : super(message: 'Limite mensuelle atteinte');
}
