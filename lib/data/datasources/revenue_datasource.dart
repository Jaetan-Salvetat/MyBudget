import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';
import 'package:mybudget/core/services/appwrite_service.dart';
import 'package:mybudget/data/models/revenue_model.dart';

class RevenueDatasource {
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  
  Future<List<RevenueModel>> getRevenues() async {
    try {
      final result = await _appwriteService.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.revenuesCollectionId,
        queries: [Query.orderDesc('\$createdAt')],
      );

      return result.documents.map((doc) {
        return RevenueModel.fromJson(doc.data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get revenues: ${e.toString()}');
    }
  }

  Future<RevenueModel> createRevenue(RevenueModel revenue) async {
    try {
      final result = await _appwriteService.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.revenuesCollectionId,
        documentId: ID.unique(),
        data: revenue.toJson(),
        permissions: []
      );

      return RevenueModel.fromJson(result.data);
    } catch (e) {
      throw Exception('Failed to create revenue: ${e.toString()}');
    }
  }

  Future<RevenueModel> updateRevenue(RevenueModel revenue) async {
    try {
      final result = await _appwriteService.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.revenuesCollectionId,
        documentId: revenue.id,
        data: revenue.toJson(),
        permissions: []
      );

      return RevenueModel.fromJson(result.data);
    } catch (e) {
      throw Exception('Failed to update revenue: ${e.toString()}');
    }
  }

  Future<void> deleteRevenue(String id) async {
    try {
      await _appwriteService.databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.revenuesCollectionId,
        documentId: id,
      );
    } catch (e) {
      throw Exception('Failed to delete revenue: ${e.toString()}');
    }
  }
}
