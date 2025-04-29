import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/config/appwrite_config.dart';

final appwriteServiceProvider = Provider<AppwriteService>((ref) {
  return AppwriteService();
});

class AppwriteService {
  late final Client client;
  late final Account account;
  late final Databases databases;
  String? currentUserId;

  AppwriteService() {
    client =
        Client()
          ..setEndpoint(AppwriteConfig.endpoint)
          ..setProject(AppwriteConfig.projectId)
          ..setSelfSigned(status: true)
          ..setLocale('fr-FR');

    account = Account(client);
    databases = Databases(client);
    _checkCurrentSession();
  }

  Future<void> _checkCurrentSession() async {
    try {
      final currentSession = await account.getSession(sessionId: 'current');
      currentUserId = currentSession.userId;
    } catch (e) {
      currentUserId = null;
    }
  }

  Future<String?> getUserId() async {
    if (currentUserId != null) return currentUserId;

    try {
      final user = await account.get();
      currentUserId = user.$id;
      return currentUserId;
    } catch (e) {
      return null;
    }
  }
}
