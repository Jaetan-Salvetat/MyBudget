import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';
import 'package:mybudget/core/services/appwrite_service.dart';
import 'package:mybudget/data/models/category_model.dart';

class CategoryDatasource {
  final AppwriteService _appwriteService = Get.find<AppwriteService>();

  Future<List<CategoryModel>> getCategories() async {
    try {
      final result = await _appwriteService.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.categoriesCollectionId
      );
      
      return result.documents.map((doc) => 
        CategoryModel.fromJson(doc.data)
      ).toList();
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  Future<CategoryModel> getCategory(String categoryId) async {
    try {
      final document = await _appwriteService.databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.categoriesCollectionId,
        documentId: categoryId
      );
      
      return CategoryModel.fromJson(document.data);
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  Future<CategoryModel> createCategory(CategoryModel category) async {
    try {
      final account = _appwriteService.account;
      final authUser = await account.get();
      final userId = authUser.$id;
      
      final data = category.toJson();
      data['user_id'] = userId;
      
      final document = await _appwriteService.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.categoriesCollectionId,
        documentId: category.id.isEmpty ? ID.unique() : category.id,
        data: data,
        permissions: []
      );
      
      return CategoryModel.fromJson(document.data);
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    try {
      final account = _appwriteService.account;
      final authUser = await account.get();
      final userId = authUser.$id;
      
      final data = category.toJson();
      data['user_id'] = userId;
      
      final document = await _appwriteService.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.categoriesCollectionId,
        documentId: category.id,
        data: data,
        permissions: []
      );
      
      return CategoryModel.fromJson(document.data);
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _appwriteService.databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.categoriesCollectionId,
        documentId: categoryId
      );
    } catch (e) {
      throw _handleDatabaseException(e);
    }
  }
  
  Exception _handleDatabaseException(dynamic e) {
    if (e is AppwriteException) {
      switch (e.code) {
        case 404:
          return Exception('Catégorie non trouvée');
        case 409:
          return Exception('Une catégorie avec ce nom existe déjà');
        default:
          return Exception('Erreur de base de données: ${e.message}');
      }
    }
    return Exception('Erreur inconnue: $e');
  }
}
