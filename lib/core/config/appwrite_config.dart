import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppwriteConfig {
  static String get endpoint => dotenv.env['APPWRITE_ENDPOINT'] ?? '';
  static String get projectId => dotenv.env['APPWRITE_PROJECT_ID'] ?? '';
  static String get databaseId => dotenv.env['APPWRITE_DATABASE_ID'] ?? '';

  static const String accountsCollection = 'accounts';
  static const String expensesCollection = 'expenses';
  static const String revenuesCollection = 'revenues';
}
