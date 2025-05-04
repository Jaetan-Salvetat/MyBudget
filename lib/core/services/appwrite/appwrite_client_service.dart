import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppwriteClientService {
  static final Client _client = Client()
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setSelfSigned(status: kDebugMode)
      .setLocale('fr-FR');

  static Client get instance => _client;

  static String get endpoint => dotenv.env['APPWRITE_ENDPOINT'] ?? '';
  static String get projectId => dotenv.env['APPWRITE_PROJECT_ID'] ?? '';
  static String get databaseId => dotenv.env['APPWRITE_DATABASE_ID'] ?? '';

  static Databases get _databases => Databases(_client);
  static Account get _account => Account(_client);

  static const String accountsCollection = 'accounts';
  static const String expensesCollection = 'expenses';
  static const String revenuesCollection = 'revenues';
  static const String categoriesCollection = 'categories';
  static const String preferencesCollection = 'preferences';

  static Future<Map<String, dynamic>> getPreferences() async {
    try {
      final user = await _account.get();
      final String userId = user.$id;

      final preferences = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: preferencesCollection,
        queries: [Query.equal('userId', userId)],
      );

      if (preferences.documents.isEmpty) {
        final defaultPreferences = <String, dynamic>{
          'userId': userId,
          'theme_mode': 2,
        };

        await _databases.createDocument(
          databaseId: databaseId,
          collectionId: preferencesCollection,
          documentId: 'unique()',
          data: defaultPreferences,
        );

        return defaultPreferences;
      }

      return preferences.documents.first.data;
    } catch (e) {
      return {'theme_mode': 2};
    }
  }

  static Future<void> updatePreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      final user = await _account.get();
      final String userId = user.$id;

      final existingPreferences = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: preferencesCollection,
        queries: [Query.equal('userId', userId)],
      );

      if (existingPreferences.documents.isEmpty) {
        final data = {'userId': userId, ...preferences};

        await _databases.createDocument(
          databaseId: databaseId,
          collectionId: preferencesCollection,
          documentId: 'unique()',
          data: data,
        );
      } else {
        final docId = existingPreferences.documents.first.$id;
        final data = {
          ...existingPreferences.documents.first.data,
          ...preferences,
        };

        await _databases.updateDocument(
          databaseId: databaseId,
          collectionId: preferencesCollection,
          documentId: docId,
          data: data,
        );
      }
    } catch (e) {
      print('Error updating preferences: $e');
    }
  }
}
