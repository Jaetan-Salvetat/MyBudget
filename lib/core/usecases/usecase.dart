import '../errors/failure.dart';

abstract class UseCase<T, Params> {
  Future<T> call(Params params);
}

class NoParams {}