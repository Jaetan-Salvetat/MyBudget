import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class AppwriteService extends GetxService {
  late Client client;
  late Account account;
  late Databases databases;

  AppwriteService() {
    client = Client();
    
    final endpoint = dotenv.env['APPWRITE_ENDPOINT'] ?? '';
    final projectId = dotenv.env['APPWRITE_PROJECT_ID'] ?? '';

    client
        .setEndpoint(endpoint)
        .setProject(projectId)
        .setSelfSigned(status: kDebugMode); // Active uniquement en mode debug

    account = Account(client);
    databases = Databases(client);
  }

  static AppwriteService get to => Get.find<AppwriteService>();
}

class AppwriteConstants {
  static String get databaseId => dotenv.env['APPWRITE_DATABASE_ID'] ?? '';
  static const String accountsCollectionId = 'accounts';
  static const String expensesCollectionId = 'expenses';
  static const String revenuesCollectionId = 'revenues';
  static const String categoriesCollectionId = 'categories';
}
