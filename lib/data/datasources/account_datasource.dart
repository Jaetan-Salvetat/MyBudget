import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/config/appwrite_constants.dart';
import 'package:mybudget/data/datasources/appwrite_client.dart';

final accountDataSourceProvider = Provider<AccountDataSource>((ref) {
  final appwriteClient = ref.watch(appwriteClientProvider);
  return AccountDataSource(appwriteClient);
});

class AccountDataSource {
  final AppwriteClient _appwriteClient;

  AccountDataSource(this._appwriteClient);

  Future<Document> createAccount(String name, String bank) async {
    final userId = await _appwriteClient.getUserId();
    
    final account = await _appwriteClient.databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.accountsCollection,
      documentId: ID.unique(),
      data: {
        'name': name,
        'bank': bank,
        'user_id': userId,
      },
      permissions: [
        Permission.read(Role.user(userId!)),
        Permission.update(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ],
    );
    
    return account;
  }

  Future<List<Document>> getAccounts() async {
    final userId = await _appwriteClient.getUserId();
    
    final accounts = await _appwriteClient.databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.accountsCollection,
      queries: [
        Query.equal('user_id', userId!)
      ],
    );
    
    return accounts.documents;
  }

  Future<Document> getAccount(String accountId) async {
    final document = await _appwriteClient.databases.getDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.accountsCollection,
      documentId: accountId,
    );
    
    return document;
  }

  Future<Document> updateAccount(String accountId, String name, String bank) async {
    final document = await _appwriteClient.databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.accountsCollection,
      documentId: accountId,
      data: {
        'name': name,
        'bank': bank,
      },
    );
    
    return document;
  }

  Future<void> deleteAccount(String accountId) async {
    await _appwriteClient.databases.deleteDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.accountsCollection,
      documentId: accountId,
    );
  }
}
