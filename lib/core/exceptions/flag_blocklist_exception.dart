sealed class FlagBlocklistException implements Exception {
  final String message;

  const FlagBlocklistException({required this.message});
}

final class FlagBlocklistMalformedException extends FlagBlocklistException {
  const FlagBlocklistMalformedException({required this.field})
    : super(message: 'Liste de blocage illisible au champ $field');

  final String field;
}
