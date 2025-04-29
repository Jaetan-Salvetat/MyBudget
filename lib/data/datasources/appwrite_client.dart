import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/config/appwrite_constants.dart';

final appwriteClientProvider = Provider<AppwriteClient>((ref) {
  return AppwriteClient();
});

class AppwriteClient {
  late final Client client;
  late final Account account;
  late final Databases databases;
  String? currentUserId;
  
  AppwriteClient() {
    client = Client()
      .setEndpoint(AppwriteConstants.endpoint)
      .setProject(AppwriteConstants.projectId)
      .setSelfSigned(status: kDebugMode)
      .setLocale('fr-FR');
    
    account = Account(client);
    databases = Databases(client);
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    try {
      final user = await account.get();
      currentUserId = user.$id;
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
