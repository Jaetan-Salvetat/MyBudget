import 'package:appwrite/appwrite.dart';
import 'package:mybudget/core/services/appwrite/appwrite_client_service.dart';
import 'package:mybudget/data/models/account_model.dart';

class AppwriteAccountService {
  static final Databases _databases = Databases(AppwriteClientService.instance);
  
  static Future<List<AccountModel>> getAccounts() async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.accountsCollection
      );
      
      return result.documents.map((doc) => 
        AccountModel.fromJson(doc.data)
      ).toList();
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<AccountModel> getAccount(String accountId) async {
    try {
      final document = await _databases.getDocument(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.accountsCollection,
        documentId: accountId
      );
      
      return AccountModel.fromJson(document.data);
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<AccountModel> createAccount(String name, String bank, {String? id}) async {
    try {
      // Récupérer l'ID de l'utilisateur actuel
      final authAccount = await Account(AppwriteClientService.instance).get();
      final userId = authAccount.$id;
      
      final document = await _databases.createDocument(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.accountsCollection,
        documentId: id ?? ID.unique(),
        data: {
          'name': name,
          'bank': bank,
          'user_id': userId
        },
        permissions: []
      );
      
      return AccountModel.fromJson(document.data);
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<AccountModel> updateAccount(AccountModel account) async {
    try {
      // Récupérer l'ID de l'utilisateur actuel
      final authAccount = await Account(AppwriteClientService.instance).get();
      final userId = authAccount.$id;
      
      final data = account.toJson();
      data['user_id'] = userId;
      
      final document = await _databases.updateDocument(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.accountsCollection,
        documentId: account.id,
        data: data,
        permissions: []
      );
      
      return AccountModel.fromJson(document.data);
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<void> deleteAccount(String accountId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.accountsCollection,
        documentId: accountId
      );
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Exception _handleDatabaseException(dynamic e) {
    if (e is AppwriteException) {
      switch (e.code) {
        case 404:
          return Exception('Compte non trouvé');
        case 409:
          return Exception('Un compte avec ce nom existe déjà');
        default:
          return Exception('Erreur de base de données: ${e.message}');
      }
    }
    return Exception('Erreur inconnue: $e');
  }
}
