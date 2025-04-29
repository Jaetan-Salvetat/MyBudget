import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/config/appwrite_constants.dart';
import 'package:mybudget/data/datasources/appwrite_client.dart';

final revenueDataSourceProvider = Provider<RevenueDataSource>((ref) {
  final appwriteClient = ref.watch(appwriteClientProvider);
  return RevenueDataSource(appwriteClient);
});

class RevenueDataSource {
  final AppwriteClient _appwriteClient;

  RevenueDataSource(this._appwriteClient);

  Future<Document> createRevenue(String name, double amount, bool isRegular, DateTime date, String accountId) async {
    final userId = await _appwriteClient.getUserId();
    
    final revenue = await _appwriteClient.databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.revenuesCollection,
      documentId: ID.unique(),
      data: {
        'name': name,
        'amount': amount,
        'isRegular': isRegular,
        'date': date.toIso8601String(),
        'accountId': accountId,
        'user_id': userId,
      },
      permissions: [
        Permission.read(Role.user(userId!)),
        Permission.update(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ],
    );
    
    return revenue;
  }

  Future<List<Document>> getRevenues() async {
    final userId = await _appwriteClient.getUserId();
    
    final revenues = await _appwriteClient.databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.revenuesCollection,
      queries: [
        Query.equal('user_id', userId!)
      ],
    );
    
    return revenues.documents;
  }

  Future<List<Document>> getRevenuesByAccount(String accountId) async {
    final userId = await _appwriteClient.getUserId();
    
    final revenues = await _appwriteClient.databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.revenuesCollection,
      queries: [
        Query.equal('user_id', userId!),
        Query.equal('accountId', accountId)
      ],
    );
    
    return revenues.documents;
  }

  Future<Document> getRevenue(String revenueId) async {
    final document = await _appwriteClient.databases.getDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.revenuesCollection,
      documentId: revenueId,
    );
    
    return document;
  }

  Future<Document> updateRevenue(String revenueId, {String? name, double? amount, bool? isRegular, DateTime? date, String? accountId}) async {
    final Map<String, dynamic> data = {};
    
    if (name != null) data['name'] = name;
    if (amount != null) data['amount'] = amount;
    if (isRegular != null) data['isRegular'] = isRegular;
    if (date != null) data['date'] = date.toIso8601String();
    if (accountId != null) data['accountId'] = accountId;
    
    final document = await _appwriteClient.databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.revenuesCollection,
      documentId: revenueId,
      data: data,
    );
    
    return document;
  }

  Future<void> deleteRevenue(String revenueId) async {
    await _appwriteClient.databases.deleteDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.revenuesCollection,
      documentId: revenueId,
    );
  }
}
