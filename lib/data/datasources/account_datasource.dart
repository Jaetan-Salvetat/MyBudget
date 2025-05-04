import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';
import 'package:mybudget/core/services/appwrite_service.dart';
import 'package:mybudget/data/models/account_model.dart';

class AccountDatasource {
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  
  Future<List<AccountModel>> getAccounts() async {
    try {
      final result = await _appwriteService.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.accountsCollectionId,
        queries: [Query.orderDesc('\$createdAt')],
      );

      return result.documents.map((doc) {
        return AccountModel.fromJson(doc.data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get accounts: ${e.toString()}');
    }
  }

  Future<AccountModel> createAccount(AccountModel account) async {
    try {
      final result = await _appwriteService.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.accountsCollectionId,
        documentId: ID.unique(),
        data: account.toJson(),
        permissions: []
      );

      return AccountModel.fromJson(result.data);
    } catch (e) {
      throw Exception('Failed to create account: ${e.toString()}');
    }
  }

  Future<AccountModel> updateAccount(AccountModel account) async {
    try {
      final result = await _appwriteService.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.accountsCollectionId,
        documentId: account.id,
        data: account.toJson(),
        permissions: []
      );

      return AccountModel.fromJson(result.data);
    } catch (e) {
      throw Exception('Failed to update account: ${e.toString()}');
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      await _appwriteService.databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.accountsCollectionId,
        documentId: id,
      );
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }
}
