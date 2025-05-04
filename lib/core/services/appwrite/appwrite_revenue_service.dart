import 'package:appwrite/appwrite.dart';
import 'package:mybudget/core/services/appwrite/appwrite_client_service.dart';
import 'package:mybudget/data/models/revenue_model.dart';

class AppwriteRevenueService {
  static final Databases _databases = Databases(AppwriteClientService.instance);
  
  static Future<List<RevenueModel>> getRevenues() async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.revenuesCollection
      );
      
      return result.documents.map((doc) => 
        RevenueModel.fromJson(doc.data)
      ).toList();
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<List<RevenueModel>> getRevenuesByAccount(String accountId) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.revenuesCollection,
        queries: [
          Query.equal('accountId', accountId)
        ]
      );
      
      return result.documents.map((doc) => 
        RevenueModel.fromJson(doc.data)
      ).toList();
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<RevenueModel> getRevenue(String revenueId) async {
    try {
      final document = await _databases.getDocument(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.revenuesCollection,
        documentId: revenueId
      );
      
      return RevenueModel.fromJson(document.data);
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<RevenueModel> createRevenue(RevenueModel revenue) async {
    try {
      final account = Account(AppwriteClientService.instance);
      final authUser = await account.get();
      final userId = authUser.$id;
      
      final data = revenue.toJson();
      data['user_id'] = userId;
      
      final document = await _databases.createDocument(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.revenuesCollection,
        documentId: ID.unique(),
        data: data,
        permissions: []
      );
      
      return RevenueModel.fromJson(document.data);
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<RevenueModel> updateRevenue(RevenueModel revenue) async {
    try {
      final account = Account(AppwriteClientService.instance);
      final authUser = await account.get();
      final userId = authUser.$id;
      
      final data = revenue.toJson();
      data['user_id'] = userId;
      
      final document = await _databases.updateDocument(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.revenuesCollection,
        documentId: revenue.id,
        data: data,
        permissions: []
      );
      
      return RevenueModel.fromJson(document.data);
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Future<void> deleteRevenue(String revenueId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteClientService.databaseId,
        collectionId: AppwriteClientService.revenuesCollection,
        documentId: revenueId
      );
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  static Exception _handleDatabaseException(dynamic e) {
    if (e is AppwriteException) {
      switch (e.code) {
        case 404:
          return Exception('Revenu non trouvé');
        default:
          return Exception('Erreur de base de données: ${e.message}');
      }
    }
    return Exception('Erreur inconnue: $e');
  }
}
