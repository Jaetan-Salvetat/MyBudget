import 'package:appwrite/models.dart';

class TokenModel {
  final String userId;
  final String secret;
  final int expire;

  TokenModel({
    required this.userId,
    required this.secret,
    required this.expire,
  });

  factory TokenModel.fromAppwriteToken(Token token) {
    return TokenModel(
      userId: token.userId,
      secret: token.$id,
      expire: int.parse(token.expire),
    );
  }
}
