import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

final appwriteClientProvider = Provider<Client>((ref) {
  final client = Client();

  final endpoint = dotenv.env['APPWRITE_ENDPOINT'] ?? '';
  final projectId = dotenv.env['APPWRITE_PROJECT_ID'] ?? '';

  client
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setSelfSigned(status: kDebugMode); // Active uniquement en mode debug

  return client;
});

final appwriteAccountProvider = Provider<Account>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Account(client);
});

final appwriteDatabaseProvider = Provider<Databases>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Databases(client);
});

class AppwriteConstants {
  static String get databaseId => dotenv.env['APPWRITE_DATABASE_ID'] ?? '';
  static const String accountsCollectionId = 'accounts';
  static const String expensesCollectionId = 'expenses';
  static const String revenuesCollectionId = 'revenues';
  static const String categoriesCollectionId = 'categories';
}
