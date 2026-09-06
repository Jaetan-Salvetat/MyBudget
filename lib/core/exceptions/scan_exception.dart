import 'package:mybudget/core/enums/ai_request_failure.dart';

sealed class ScanException implements Exception {
  const ScanException({required this.message});
  final String message;
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

final class ScanUnreadablePhotoException extends ScanException {
  const ScanUnreadablePhotoException()
    : super(message: 'Cette photo n\'a pas pu être ouverte');
}

final class ScanRemoteException extends ScanException {
  ScanRemoteException(this.failure) : super(message: failure.label);

  final AiRequestFailure failure;
}
